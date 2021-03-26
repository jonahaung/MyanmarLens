//
//  Service.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 28/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation
import AVKit
import NaturalLanguage
import Vision

class ServiceManager: ObservableObject {
    
    @Published var zoom: CGFloat = 0 {
        willSet {
            videoService.sliderValueDidChange(Float(zoom/20))
        }
    }
    var isTracking = false {
        didSet {
            guard oldValue != self.isTracking else { return }
            if isTracking {
                SoundManager.vibrate(vibration: .light)
            } else {
                reset()
            }
            fps = isTracking ? 10 : 3
        }
    }
    @Published var isStopped = false {
        willSet {
            objectWillChange.send()
        }
        didSet {
            !oldValue ? videoService.stop() : videoService.start()
        }
    }
    
    @Published var fps: Int = 5 {
        didSet {
            
            videoService.fps = self.fps
            objectWillChange.send()
        }
    }
    
    @Published var videoQuality: VideoQuality = VideoQuality.current {
        willSet {
            objectWillChange.send()
        }
        didSet{
            guard oldValue != self.videoQuality else { return }
            userDefaults.videoQuality = videoQuality.rawValue
            videoService.videoQuality = videoQuality
        }
    }

    @Published var showLoading: Bool = false {
        willSet {
            objectWillChange.send()
        }
    }
    
    @Published var displayingResults = false {
        willSet {
            objectWillChange.send()
        }
    }
    
    private(set) var currentPixelBuffer: CVPixelBuffer?
    
    private let videoService: VideoService
    private let ocrService: OcrService
    private let boxService: BoxService
    private let translateService: TranslateService
    private let perspectiveService: LiveOcrService

    let overlayView: OverlayView
    
    init() {
        overlayView = OverlayView()
        videoService = VideoService(overlayView)
        boxService = BoxService(overlayView)
        ocrService = OcrService(overlayView)
        perspectiveService = LiveOcrService(overlayView)
        translateService = TranslateService()
       
        videoService.captureSession.startRunning()
        
        NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange), name: Notification.Name.AVCaptureDeviceSubjectAreaDidChange, object: nil)
        videoService.delegate = self
        ocrService.delegate = self
        overlayView.delegate = self
        
        translateService.delegate = self
        perspectiveService.delegate = self
    }
    
    func configure() {
        fps = videoService.fps
        videoService.configure()
        videoService.start()
        UIApplication.shared.isIdleTimerDisabled = true
        subjectAreaDidChange()
    }
    
    deinit {
        videoService.captureSession.stopRunning()
        NotificationCenter.default.removeObserver(self)
        print("Service Manager")
    }
}

// Video Service
extension ServiceManager: VideoServiceDelegate {
    
    func videoService(_ service: VideoService, captureFrame cvPixelBuffer: CVImageBuffer) {
        
        
        
        let ciImage = cvPixelBuffer.ciImage
        
        if let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) {
            
//            let imageRect = CGRect(origin: .zero, size: CurrentSession.videoSize)
//
//            let croppingRect = OcrService.regionOfInterest.normalized().viewRect(for: imageRect.size)
//
//            guard let cropped = cgImage.cropping(to: croppingRect) else {
//                return
//            }
//
//
//            let uiImage = UIImage(cgImage: cropped)
//
//            let renderer = UIGraphicsImageRenderer(size: imageRect.size)
//
//            let result = renderer.image { ctx in
//                // fill the background with white so that translucent colors get lighter
//                UIColor.black.set()
//                ctx.fill(imageRect)
//                uiImage.draw(in: croppingRect, blendMode: .normal, alpha: 1)
//            }
            
            
            DispatchQueue.main.async {
                
                self.showLoading = true
                self.displayingResults = true
                self.overlayView.flashToBlack(isCapture: true)
                self.overlayView.image = UIImage(cgImage: cgImage)
                self.ocrService.handle(with: cvPixelBuffer)
            }
            
            
        }
        
    }
    
    func videoService(_ service: VideoService, didOutput sampleBuffer: CVImageBuffer) {
        currentPixelBuffer = sampleBuffer
        guard isTracking else {
            ObjectDetector.text(for: sampleBuffer) { [weak self] quad in
                guard let self = self, let quad = quad else { return }
                DispatchQueue.main.async {
                    self.boxService.handle(quad)
                }
            }
            return

        }
        SoundManager.vibrate(vibration: .selection)
        perspectiveService.handle(sampleBuffer)
    }
}

// OCR Serviece
extension ServiceManager: OcrServiceDelegate {
    
    func ocrService(displayNoResult service: OcrService) {
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            self.reset()
        }
    }
    
    func ocrService(_ service: OcrService, didGetTextRects textRects: [TextRect]) {
        boxService.handle(textRects)
//        translateService.handle(textRects: textRects)
    }
}

// Live OCR Service
extension ServiceManager: LiveOcrServiceDelegate {
    
    func liveOcrService(_ service: LiveOcrService, didTrack quad: Quadrilateral) {
        overlayView.apply(quad.applying(overlayView.videoPreviewLayer.layerTransform))
    }
    
    func liveOcrService(_ service: LiveOcrService, didGet quad: Quadrilateral) {
        
        DispatchQueue.main.async {
            guard self.isTracking else { return }
            
            let isMyanmar = userDefaults.sourceLanguage == .burmese
            if let trTurples = quad.textRects {
                
                let colors = UIImageColors(background: .separator, primary: .white, secondary: .systemYellow, detail: .black)
                
                let containerSize = self.overlayView.bounds.size
                let textRects = trTurples.map{ TextRect($0.0, $0.1.normalized().viewRect(for: containerSize), _isMyanmar: isMyanmar, _colors: colors)}
                self.translateService.handle(textRects: textRects)
            }
        }
    }
}

// Translate Serviece
extension ServiceManager: TranslateServiceDelegate {
    func translateService(_ service: TranslateService, didFinishTranslation textRects: [TextRect]) {
        showLoading = false
        boxService.handle(textRects)
        
    }
}

// Overlay View
extension ServiceManager: OverlayViewDelegate {
    func overlayView(didTapScreen view: OverlayView, canreset: Bool) {
        if canreset {
            reset()
        }else if isStopped {
            isStopped = false
        }
    }
}


// Others

extension ServiceManager {
    
    // Action
    func didTapActionButton() {
        SoundManager.vibrate(vibration: .light)
        overlayView.flashToBlack(isCapture: true)
        
        guard let cvPixelBuffer = currentPixelBuffer else { return }
        let ciImage = cvPixelBuffer.ciImage
        
        guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else { return }
        self.showLoading = true
        self.displayingResults = true
        self.overlayView.flashToBlack(isCapture: true)
        self.overlayView.image = UIImage(cgImage: cgImage)
        
        videoService.stop {
            DispatchQueue.main.async {
                self.ocrService.handle(with: cvPixelBuffer)
            }
        }
        
    }
    
    func reset() {
        
        ocrService.cancel()
        boxService.reset()
        overlayView.image = nil
//        overlayView.zoomGestureController.image = nil
        showLoading = false
        displayingResults = false
        overlayView.apply(nil)
        subjectAreaDidChange()
        videoService.start()
    }
    
    @objc private func subjectAreaDidChange() {
        
        guard !displayingResults else { return }
        try? CaptureSession.current.resetFocusToAuto()
    }
    
    // Skew
    func didTapSkew() {
        if let buffer = ocrService.currentPixelBuffer {
            ObjectDetector.rectangle(for: buffer) {[weak self] quad in
                guard let self = self else {
                    return
                }
                DispatchQueue.main.async {
                    if let quad = quad {
                        self.overlayView.apply(quad.applying(self.overlayView.videoPreviewLayer.layerTransform))
//                        self.overlayView.quadView.editable = true
                    } else {
                        ObjectDetector.attention(for: buffer.ciImage) {[weak self] quad in
                            guard let self = self else {
                                return
                            }
                            DispatchQueue.main.async {
                                if let quad = quad {
                                    self.overlayView.apply(quad.applying(self.overlayView.videoPreviewLayer.layerTransform))
//                                    self.overlayView.quadView.editable = true
                                }
                            }
                        }
                    }
                }
                
            }
        }
    }
    // Share
    func didTapShareButton() {
        let image = overlayView.asImage()
        image.shareWithMenu()
    }
    // Save
    func saveAsImage() {
        let image = overlayView.asImage()
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        let x = UIAlertController(style: .alert)
        x.set(title: "Image Saved!", font: UIFont.preferredFont(forTextStyle: .headline))
        x.addAction(title: "OK")
        x.show()
    }
    // FPS
    func didTappedFPS() {
        SoundManager.vibrate(vibration: .light)
        if fps <= 15 {
            if fps == 15 {
                fps = 3
            }else {
                fps += 1
            }
        }
    }
    
}
