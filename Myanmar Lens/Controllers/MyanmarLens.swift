//
//  MyanmarLens.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 20/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox
import SwiftyTesseract
import SwiftyTesseractRTE
import CoreData

final class MyanmarLensController: UIViewController {
    
    private let excludeLayer: CAShapeLayer = {
        $0.fillRule = .evenOdd
        $0.fillColor = UIColor.black.cgColor
        $0.opacity = 0.4
        return $0
    }(CAShapeLayer())
    
    private let actionButton: UIButton = {
        $0.tintColor = UIColor.systemYellow
        $0.setPreferredSymbolConfiguration(.init(font: UIFont.preferredFont(forTextStyle: .largeTitle)), forImageIn: .normal)
        $0.setImage(UIImage(systemName: "video.fill"), for: .normal)
        $0.setTitleColor(UIColor.yellow, for: .normal)
        return $0
    }(UIButton())
    
    private let doneButton: UIButton = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setTitle("Done", for: .normal)
        $0.setTitleColor(UIColor.yellow, for: .normal)
        return $0
    }(UIButton())
    
    private let resultLabel: UILabel = {
        $0.textAlignment = .center
        $0.numberOfLines = 20
        $0.textColor = .white
        $0.font = UIFont.preferredFont(forTextStyle: .title2)
        return $0
    }(UILabel())
    
    private let previewView: UIView = {
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return $0
    }(UIView())
    
    private let regionOfInterest: UIView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = .clear
        return $0
    }(UIView())
    
    private var regionOfInterestWidth: NSLayoutConstraint!
    private var regionOfInterestHeight: NSLayoutConstraint!
    
    private var engineIsRunning = false {
        didSet {
            guard oldValue != engineIsRunning else { return }
            engine.recognitionIsActive = engineIsRunning
            let buttonImageName = engineIsRunning ? "video.slash" : "video.fill"

            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.actionButton.setImage(UIImage(systemName: buttonImageName), for: .normal)
            }
            
        }
    }
    
    private var engine: RealTimeEngine!
    private lazy var swiftyTesseract = SwiftyTesseract(language: .burmese)
    private lazy var myMemoryTranslator = MyMemoryTranslation.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupEngine()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        engine.bindPreviewLayer(to: previewView)
        engine.regionOfInterest = regionOfInterest.frame
        previewView.layer.addSublayer(regionOfInterest.layer)
        fillOpaqueAroundAreaOfInterest()
    }
    deinit {
        engineIsRunning = false
        print("Deinit")
    }
}

// Recognizer

extension MyanmarLensController {
    
    private func setupEngine() {
        
        engine = RealTimeEngine(swiftyTesseract: swiftyTesseract, desiredReliability: .verifiable) { [weak self] recognizedString in
            guard let `self` = self else { return }
            if !recognizedString.isEmpty {
                self.engineIsRunning = false
                let clean = recognizedString.cleanUpMyanmarTexts()
                self.myMemoryTranslator.translate(text: clean, from: "my", to: "en") { (result, err) in
                    if let err = err {
                        DispatchQueue.main.async {
                            self.resultLabel.text = err.localizedDescription
                        }

                        return
                    }
                    if let result = result {
                        DispatchQueue.main.async {
                            self.resultLabel.text = result
                        }
                    }
                }
            }
        }
        engine.recognitionIsActive = false
        engine.startPreview()
    }
}

// Setup

extension MyanmarLensController {
    
    fileprivate func setup() {
        
        previewView.frame = view.bounds.inset(by: view.safeAreaInsets)
        view.addSubview(previewView)
        previewView.addSubview(regionOfInterest)
        
        regionOfInterest.centerXAnchor.constraint(equalTo: previewView.centerXAnchor).isActive = true
        regionOfInterest.bottomAnchor.constraint(equalTo: previewView.centerYAnchor, constant: -20).isActive = true
        regionOfInterestWidth = regionOfInterest.widthAnchor.constraint(equalToConstant: previewView.bounds.width / 1.5)
        regionOfInterestWidth.isActive = true
        regionOfInterestHeight = regionOfInterest.heightAnchor.constraint(equalToConstant: 50)
        regionOfInterestHeight.isActive = true
        
        let stackView: UIStackView = {
            $0.axis = .vertical
            $0.alignment = .center
            $0.distribution = .fill
            $0.spacing = 10
            $0.translatesAutoresizingMaskIntoConstraints = false
            return $0
        }(UIStackView(arrangedSubviews: [actionButton, resultLabel]))
        
        view.addSubview(stackView)
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor).isActive = true
        
        view.addSubview(doneButton)
        doneButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        doneButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10).isActive = true
        
        doneButton.addTarget(self, action: #selector(didTapDone(_:)), for: .touchUpInside)
        resultLabel.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
        actionButton.addTarget(self, action: #selector(recognitionButtonTapped(_:)), for: .touchUpInside)
//        actionButton.addTarget(self, action: #selector(recognitionButtonHodlDown(_:)), for: .touchDown)
    }
    
    private func fillOpaqueAroundAreaOfInterest() {
        let rect = previewView.bounds
        let areaOfInterestFrame = regionOfInterest.frame
        
        let path = UIBezierPath(rect: rect)
        let areaOfInterestPath = UIBezierPath(roundedRect: areaOfInterestFrame, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 12, height: 12))
        path.append(areaOfInterestPath)
        path.usesEvenOddFillRule = true
        
        excludeLayer.path = path.cgPath
        previewView.layer.addSublayer(excludeLayer)
    }
    
    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        let translate = sender.translation(in: regionOfInterest)
        
        UIView.animate(withDuration: 0) {
            self.regionOfInterestWidth.constant += translate.x
            self.regionOfInterestHeight.constant += translate.y
        }
        
        sender.setTranslation(.zero, in: regionOfInterest)
        viewDidLayoutSubviews()
    }
    
    @objc private func recognitionButtonHodlDown(_ sender: Any) {
        engineIsRunning = true
    }
    
    @objc private func recognitionButtonTapped(_ sender: Any) {
        engineIsRunning.toggle()
    }
    
    @objc private func didTapDone(_ sender: Any) {
        engineIsRunning = false
        dismiss(animated: true, completion: nil)
    }
}


