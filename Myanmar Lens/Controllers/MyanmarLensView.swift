//
//  MyanmarLensView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 20/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit
import AVKit

typealias LanguagePair = (Language, Language)

protocol MyanmarLensViewDelegate: class {
    func myanmarLensView(didtapToggleLanguageButton view: MyanmarLensView)
    func myanmarLensView(didtapLeftButton view: MyanmarLensView)
    func myanmarLensView(didtapRightButton view: MyanmarLensView)
    func myanmarLensView(didTapDoneButton view: MyanmarLensView)
    func myanmarLensView(didTapActionButton start: Bool, view: MyanmarLensView)
    func myanmarLensView(didTapResetButton view: MyanmarLensView)
}

final class MyanmarLensView: UIView {
    
    weak var delegate: MyanmarLensViewDelegate?
    
    var languagePair = LanguagePair(.my, .my) {
        didSet {
            guard languagePair != oldValue else { return }
            leftButton.setTitle(languagePair.0.description, for: .normal)
            rightButton.setTitle(languagePair.1.description, for: .normal)
        }
    }
    
    var flashLightOn = false {
        didSet {
            guard flashLightOn != oldValue else { return }
            guard
                let device = AVCaptureDevice.default(for: AVMediaType.video),
                device.hasTorch
            else { return }

            do {
                try device.lockForConfiguration()
                device.torchMode = flashLightOn ? .on : .off
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        }
    }
    
    private let excludeLayer: CAShapeLayer = {
        $0.fillRule = .evenOdd
        $0.fillColor = UIColor.black.cgColor
        $0.opacity = 0.5
        return $0
    }(CAShapeLayer())

    private let toolBar: UIToolbar = {
        $0.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        $0.setShadowImage(UIImage(), forToolbarPosition: .any)
        $0.clipsToBounds = false
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIToolbar())
    
    private let actionButton: UIButton = {
        $0.setPreferredSymbolConfiguration(.init(pointSize: 70, weight: .medium), forImageIn: .normal)
        $0.setPreferredSymbolConfiguration(.init(pointSize: 70, weight: .medium), forImageIn: .highlighted)
        $0.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        $0.setImage(UIImage(systemName: "circle"), for: .highlighted)
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIButton(type: .custom))
    
    let translatedResultLabel: UILabel = {
        $0.textAlignment = .center
        $0.numberOfLines = 20
        $0.textColor = UIColor.systemTeal
        $0.font = UIFont.monoSpacedFont
        $0.text = "Press and hold the ● bottom to start"
        $0.setContentHuggingPriority(UILayoutPriority(rawValue: 754), for: .vertical)
        return $0
    }(UILabel())
    
    let recognizedLabel: UILabel = {
        $0.textAlignment = .center
        $0.numberOfLines = 20
        $0.textColor = UIColor.systemGray3
        $0.font = UIFont.myanmarFont
        $0.setContentHuggingPriority(UILayoutPriority(rawValue: 755), for: .vertical)
        return $0
    }(UILabel())
    
    let previewView: UIView = {
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return $0
    }(UIView())
    
    let regionOfInterest: UIView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = .clear
        $0.isUserInteractionEnabled = true
        return $0
    }(UIView())
    
    private let leftButton: UIButton = {
        $0.setTitleColor(UIColor.systemGray3, for: .normal)
        $0.setTitle("LeftButton", for: .normal)
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIButton())
    
    private let rightButton: UIButton = {
        $0.setTitleColor(UIColor.systemGray3, for: .normal)
        $0.setTitle("RightButton", for: .normal)
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIButton())
    
    private let activityIndicator: UIActivityIndicatorView = {
        $0.hidesWhenStopped = true
        $0.color = UIColor.systemGray
        return $0
    }(UIActivityIndicatorView(style: .large))
    
    private let languageToggleButton: UIButton = {
        $0.setPreferredSymbolConfiguration(.init(font: UIFont.preferredFont(forTextStyle: .title1)), forImageIn: .normal)
        $0.setImage(UIImage(systemName: "repeat"), for: .normal)
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIButton())
    
    private lazy var stackView: UIStackView = {
        $0.axis = .vertical
        $0.alignment = .center
        $0.distribution = .fill
        $0.spacing = UIStackView.spacingUseSystem
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIStackView(arrangedSubviews: [activityIndicator, recognizedLabel, translatedResultLabel]))
    
    private lazy var languageStackView: UIStackView = {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.distribution = .fill
        $0.spacing = UIStackView.spacingUseSystem
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIStackView(arrangedSubviews: [leftButton, languageToggleButton, rightButton]))
    
    private var regionOfInterestWidth: NSLayoutConstraint!
    private var regionOfInterestHeight: NSLayoutConstraint!
    
    private var heartButton: UIBarButtonItem?
    private var refreshButton: UIBarButtonItem?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

extension MyanmarLensView {
    
    private func setup() {
        
        tintColor = UIColor.systemGray4
    
        previewView.frame = bounds
        
        addSubview(previewView)
        previewView.addSubview(regionOfInterest)
        addSubview(toolBar)
        addSubview(languageStackView)
        addSubview(actionButton)
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            regionOfInterest.centerXAnchor.constraint(equalTo: previewView.centerXAnchor),
            regionOfInterest.bottomAnchor.constraint(equalTo: previewView.centerYAnchor, constant: -50),
            
            languageStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 40),
            languageStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            toolBar.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor),
            toolBar.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor),
            toolBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionButton.bottomAnchor.constraint(equalTo: toolBar.topAnchor, constant: 5),
            
            stackView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.95),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.topAnchor.constraint(equalTo: centerYAnchor, constant: -20),
            
            
        ])
        
        setupRegionOfInterestConstraints()
    
        setupActions()
    }
    
    private func setupRegionOfInterestConstraints() {
        regionOfInterestWidth = regionOfInterest.widthAnchor.constraint(equalToConstant: previewView.bounds.width / 1.5)
        regionOfInterestWidth.isActive = true
        regionOfInterestHeight = regionOfInterest.heightAnchor.constraint(equalToConstant: 50)
        regionOfInterestHeight.isActive = true
        addConstraint(regionOfInterestWidth)
        addConstraint(regionOfInterestHeight)
    }
    
    func fillOpaqueAroundAreaOfInterest() {
        let rect = previewView.bounds
        let areaOfInterestFrame = regionOfInterest.frame
        
        let path = UIBezierPath(rect: rect)
        let areaOfInterestPath = UIBezierPath(roundedRect: areaOfInterestFrame, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 8, height: 8))
        path.append(areaOfInterestPath)
        path.usesEvenOddFillRule = true
        
        excludeLayer.path = path.cgPath
        previewView.layer.addSublayer(excludeLayer)
    }
    
    
    
    private func setupActions() {
        actionButton.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
        leftButton.addTarget(self, action: #selector(didTapLeftButton(_:)), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(didTapRightButton(_:)), for: .touchUpInside)
        languageToggleButton.addTarget(self, action: #selector(didTapToggleLanguageButton(_:)), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(didTapDownActionButton(_:)), for: .touchDown)
        actionButton.addTarget(self, action: #selector(didTapUpActionButton(_:)), for: .touchUpInside)
        
        heartButton = UIBarButtonItem(image: UIImage(systemName: "heart.fill"), style: .plain, target: self, action: #selector(didTapReset(_:)))
        heartButton?.tintColor = UIColor.systemPink
        heartButton?.isEnabled = false
        refreshButton = UIBarButtonItem(image: UIImage(systemName: "arrow.2.circlepath"), style: .plain, target: self, action: #selector(didTapReset(_:)))
        refreshButton?.isEnabled = false
        
        toolBar.items = [
            UIBarButtonItem(image: UIImage(systemName: "bolt.fill"), style: .plain, target: self, action: #selector(didTapFlashLight(_:))),
            refreshButton!,
            heartButton!,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(didTapDone(_:)))
        ]

    }
    
    
    
    @objc private func didTapRightButton(_ sender: Any) {
        delegate?.myanmarLensView(didtapRightButton: self)
    }
    
    @objc private func didTapLeftButton(_ sender: Any) {
        delegate?.myanmarLensView(didtapLeftButton: self)
    }
    
    @objc private func didTapToggleLanguageButton(_ sender: Any) {
        delegate?.myanmarLensView(didtapToggleLanguageButton: self)
    }
    
   
    @objc private func didTapUpActionButton(_ sender: UIButton) {
        delegate?.myanmarLensView(didTapActionButton: false, view: self)
    }
    @objc private func didTapDownActionButton(_ sender: Any) {
        SoundManager.vibrate(vibration: .light)
        recognizedLabel.text = nil
        translatedResultLabel.text = nil
        delegate?.myanmarLensView(didTapActionButton: true, view: self)
    }
    
    @objc private func didTapFlashLight(_ sender: UIBarButtonItem) {
        flashLightOn.toggle()
        
        let imageName = flashLightOn ? "bolt.slash" : "bolt.fill"
        sender.image = UIImage(systemName: imageName)
    }
    
    @objc private func didTapReset(_ sender: Any) {
        heartButton?.isEnabled = false
        refreshButton?.isEnabled = false
        delegate?.myanmarLensView(didTapResetButton: self)
        
    }
    
    @objc private func didTapDone(_ sender: Any) {
        delegate?.myanmarLensView(didTapDoneButton: self)
    }
    
    func engineIsRunning(isRunning: Bool) {
        if isRunning {
            activityIndicator.startAnimating()
            heartButton?.isEnabled = false
            refreshButton?.isEnabled = false
        }else {
            activityIndicator.stopAnimating()
            heartButton?.isEnabled = true
            refreshButton?.isEnabled = true
        }
    }
    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        let regionTranslate = sender.translation(in: regionOfInterest)
        UIView.animate(withDuration: 0.1) {
            self.regionOfInterestWidth.constant += regionTranslate.x
            self.regionOfInterestHeight.constant += regionTranslate.y
        }
        
        sender.setTranslation(.zero, in: regionOfInterest)
        setNeedsLayout()
        layoutIfNeeded()
    }
}
