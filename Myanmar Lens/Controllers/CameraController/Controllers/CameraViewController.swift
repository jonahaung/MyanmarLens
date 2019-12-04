//
//  ViewController.swift
//  MathSolver
//
//  Created by Khoa Pham on 26.06.2018.
//  Copyright © 2018 onmyway133. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class CameraViewController: UIViewController {
    
    private let cameraController = CameraController()
    private let visionService = VisionService()
    private let boxService = BoxService()
    private let ocrService = OCRService()
    private let labelService = LabelService()
    private let translateService = TranslateService()
    
    internal var languagePair = LanguagePair(.burmese, .burmese) {
        didSet {

            visionService.languagePair = languagePair
            translateService.languagePair = languagePair
            navigationItem.title = languagePair.0.description
            cameraController.targetLanguage.title = languagePair.1.description.uppercased()
            cameraController.sourceLanguage.title = languagePair.0.description.uppercased()
            if cameraController.picker != nil {
                cameraController.picker?.removeFromSuperview()
                cameraController.picker = nil
            }
        }
    }
    
    private var isActive = false {
        didSet {
            visionService.isActive = isActive
            SoundManager.playSound(tone: .Tock)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = [.top, .bottom]
        
        navigationItem.rightBarButtonItems = [cameraController.targetLanguage, cameraController.arrowButton, cameraController.sourceLanguage]
        addDefaultBackgroundImageView()
        add(childController: cameraController)
        cameraController.view.frame = view.bounds
        boxService.overlayLayer = cameraController.overlayLayer
        
        cameraController.delegate = self
        visionService.delegate = self
        ocrService.delegate = self
        translateService.delegate = self
        
        languagePair = userDefaults.languagePair
        
        cameraController.actionButton.addTarget(self, action: #selector(didTouchUpActionButton(_:)), for: .touchUpInside)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setToolbarHidden(false, animated: true)
        setToolbarItems(cameraController.getToolbarItems(), animated: true)
        cameraController.videoManager.delegate = self
        cameraController.videoManager.captureSession.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        visionService.parentBounds = cameraController.overlayLayer.frame
        var insets = view.safeAreaInsets
        insets.bottom = 2 * insets.top
        visionService.regionOfInterest = cameraController.view.bounds.inset(by: insets)
        cameraController.overlayLayer.regionOfInterest = visionService.regionOfInterest
    }
    
    deinit {
        print("Deinit")
    }
}


// Camera
extension CameraViewController: CameraControllerDelegate {
    
    @objc private func didTouchUpActionButton(_ sender: UIButton) {
        isActive.toggle()
        boxService.clearlayers()
        labelService.clearLabels()
        
    }
}

// Video
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isActive else { return }
        visionService.handle(sampleBuffer: sampleBuffer)
    }
}


// Vision
extension CameraViewController: VisionServiceDelegate {
    
    // Drawing Boxes
    func visionService(_ service: VisionService, drawBoxes rects: [CGRect]) {
        let color = UIColor.systemIndigo
        DispatchQueue.main.async {
            self.boxService.drawBoxes(rects: rects, color: color)
        }
    }
    
    // Mya
    func visionService(_ service: VisionService, didGetImageRects imageRects: [ImageRect]) {
        self.ocrService.handle(imageRects: imageRects)
        DispatchQueue.main.async {
            let rects = imageRects.map{ $0.1}
            self.boxService.drawBoxes(rects: rects, color: .lightGray)
        }
    }
    
    // Eng
    func visionService(_ service: VisionService, didGetTextRects textRects: [TextRect]) {
        isActive = false
        service.reset()
        DispatchQueue.main.async {
            self.boxService.drawBoxes(rects: textRects.map{$0.1}, color: .lightGray)
            self.labelService.handle(textRects: textRects, on: self.cameraController.view, isMyanmar: false)
            self.translateService.handle(textRects: textRects)
        }
    }
}

// OCR
extension CameraViewController: OCRServiceDelegate {
    
    func ocrService(_ service: OCRService, didGetResults textRects: [TextRect]) {
        SoundManager.vibrate(vibration: .success)
        labelService.handle(textRects: textRects, on: cameraController.view, isMyanmar: true)
        cameraController.activityIndicator.startAnimating()
        translateService.handle(textRects: textRects)
    }
}

// Translate

extension CameraViewController: TranslateServiceDelegate {
    func translateService(_ service: TranslateService, didFinishTranslation textRects: [TextRect]) {
        labelService.handle(textRects: textRects, on: cameraController.view, isMyanmar: languagePair.0 == .burmese)
        cameraController.activityIndicator.stopAnimating()
    }
}
