//
//  Service.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 28/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation
import AVKit
import Combine
import NaturalLanguage
import SwiftUI
enum CameraStage {
    case Start, Stop, Initial
}


class ServiceManager: ObservableObject {
    
    @Published var zoom: CGFloat = 0 {
        willSet {
            videoService.sliderValueDidChange(Float(zoom/20))
        }
    }
   
    private var isInitial = false
    @Published var selectedButton: SelectedButton = .none {
        didSet {
            if oldValue == self.selectedButton {
                self.selectedButton = .none
                return
            }
            isInitial = true
            switch self.selectedButton {
                
            case .textColor:
                choice = textTheme.rawValue
            default:
                break
            }
            isInitial = false
            SoundManager.vibrate(vibration: .medium)
            objectWillChange.send()
            
        }
    }
    @Published var fps: Int = 5 {
        didSet {
            guard oldValue != self.fps else { return }
            videoService.fps = self.fps
            objectWillChange.send()
        }
    }
    @Published var videoQuality: VideoQuality = VideoQuality.current {
        didSet{
            guard oldValue != self.videoQuality else { return }
            userDefaults.videoQuality = videoQuality.rawValue
            videoService.videoQuality = videoQuality
            objectWillChange.send()
        }
    }
    @Published var choice = 0 {
        didSet {
            guard !isInitial else {
                return
            }
            switch selectedButton {
            case .flash:
                flashState = flashState == .on ? .off : .on
            case .textColor:
                self.textTheme = TextTheme(rawValue: choice) ?? TextTheme.Adaptive
            default:
                break
            }
            
        }
        
    }
    
    var detectedLanguage: NLLanguage {
        get {
            return userDefaults.sourceLanguage
        }
        set {
            
            
            guard userDefaults.sourceLanguage != newValue else { return }
            if newValue == targetLanguage {
                targetLanguage = userDefaults.sourceLanguage
            }
            userDefaults.sourceLanguage = newValue
            DispatchQueue.main.async {
                
                self.objectWillChange.send()
            }
        }
    }
    var targetLanguage: NLLanguage {
        get {
            return userDefaults.targetLanguage
        }
        set {
            guard userDefaults.targetLanguage != newValue else { return }
            userDefaults.targetLanguage = newValue
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    @Published var showLoading: Bool = false {
        willSet {
            objectWillChange.send()
        }
    }
    
    @Published var flashState: CaptureSession.FlashState = .off {
        didSet {
            
            guard let device = videoService.captureDevice, device.isTorchAvailable else { return  }
            
            do {
                try device.lockForConfiguration()
            } catch {
                print(error)
            }
            
            defer {
                device.unlockForConfiguration()
            }
            switch flashState {
            case .on:
                device.torchMode = .on
            case .off:
                device.torchMode = .off
            }
            objectWillChange.send()
        }
    }
    @Published var textTheme: TextTheme = userDefaults.textTheme {
        didSet {
            userDefaults.textTheme = self.textTheme
            objectWillChange.send()
        }
    }
    
    private let videoService: VideoService
    private let ocrService: OcrService
    private let boxService: BoxService
    private let translateService: TranslateService
    let overlayView: OverlayView
    
    init() {
        overlayView = OverlayView()
        videoService = VideoService()
        translateService = TranslateService()
        boxService = BoxService(_overlayView: overlayView)
        ocrService = OcrService(_overlayView: overlayView)
        translateService.delegate = self
        ocrService.delegate = self
        overlayView.delegate = self
        videoService.videoServiceDelegate = ocrService
        
        videoService.configure(layer: overlayView.videoPreviewLayer)
        videoService.captureSession.startRunning()
        NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange), name: Notification.Name.AVCaptureDeviceSubjectAreaDidChange, object: nil)
    }
    
    func configure() {
        
        videoService.start {
            self.videoService.canOutputBuffer = true
        }
        fps = videoService.fps
    }
    
    func stop() {
        videoService.captureSession.stopRunning()
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        if device.torchMode == .on {
            toggleFlash()
        }
    }
    
    
    deinit {
        stop()
        NotificationCenter.default.removeObserver(self)
        print("Service Manager")
    }
    
    // Action
    func didTapActionButton() {
        guard !showLoading else {
            SoundManager.vibrate(vibration: .warning)
            return
        }
        if overlayView.image != nil {
            SoundManager.vibrate(vibration: .light)
            overlayView.clear()
        } else {
            videoService.stop {[weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.showLoading = true
                }
                self.ocrService.capture()
            }
        }
    }
}



// OCR Serviece
extension ServiceManager: OcrServiceDelegate {
    func ocrService(_ service: OcrService, didGetImage image: UIImage) {
        DispatchQueue.main.async {
            self.overlayView.flashToBlack()
            self.overlayView.image = image
        }
    }
    
    func ocrService(_ service: OcrService, didCaptureRectangle quad: Quadrilateral?) {
        
    }
    func ocrService(_ service: OcrService, didCapture quad: Quadrilateral?) {
        DispatchQueue.main.async {
            self.overlayView.apply(quad)
            self.fps = quad == nil ? 3 : 5
            
        }
    }
    func ocrService(_ service: OcrService, didFailedCapture quad: Quadrilateral?) {
        service.clear()
        self.videoService.start {[weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.self.showLoading = false
                self.subjectAreaDidChange()
            }
       }
    }
    
    
    func ocrService(_ service: OcrService, didGetStableTextRects textRects: [TextRect]) {
        
        translateService.handle(textRects: textRects)
    }
}
// Box Serviece
extension ServiceManager: TranslateServiceDelegate {
    func translateService(_ service: TranslateService, didFinishTranslation textRects: [TextRect]) {
        self.boxService.handle(textRects)
        self.showLoading = false
    }
}

// Overlay View
extension ServiceManager: OverlayViewDelegate {
    func overlayView(didClearScreen view: OverlayView) {
        boxService.clearlayers()
        showLoading = false
        ocrService.clear()
        videoService.start()
        subjectAreaDidChange()
    }
    
    
}


// Others

extension ServiceManager {
    
    
    // Flash
    func toggleFlash() {
        flashState = CaptureSession.current.toggleFlash()
    }
    
    //  Text Theme
    func toggleTextTheme() {
        textTheme = textTheme == .BlackAndWhite ? .Adaptive : .BlackAndWhite
        
    }
}

// Subject Area
extension ServiceManager {
    
    @objc private func subjectAreaDidChange() {
        
        do {
            try CaptureSession.current.resetFocusToAuto()
        } catch {
            let error = ImageScannerControllerError.inputDevice
            print(error)
            return
        }
        
        /// Remove the focus rectangle if one exists
        CaptureSession.current.removeFocusRectangleIfNeeded(overlayView.focusRectangle, animated: true)
        ocrService.clear()
    }
    
}

// Language
extension ServiceManager {
    func didTapTargetLanguage() {
        SoundManager.vibrate(vibration: .medium)
        let alert = UIAlertController(title: "Target Language", message: "Pls select one of the following target languages", preferredStyle: .actionSheet)
        let index = Languages.targetLanguages.firstIndex(of: userDefaults.languagePair.target) ?? 1
        
        alert.addPickerView(values: [ Languages.targetLanguages.map{ $0.localName }], initialSelection: PickerViewViewController.Index(0, index)) { (_, _, index, values) in
            let value = values[index.column][index.row]
            let selectedLanguages = Languages.targetLanguages.filter{ $0.localName == value }
            if let language = selectedLanguages.first {
                let newValue = language.rawValue
                let newLanguage = NLLanguage(newValue)
                alert.message = newLanguage.rawValue
                self.targetLanguage = newLanguage
                
            }
        }
        alert.addAction(title: "OK", style: .cancel, handler: nil)
        alert.show()
    }
    
    func didTapSourceLanguage() {
        SoundManager.vibrate(vibration: .medium)
        let alert = UIAlertController(title: "Source Language", message: "Pls select one of the following source languages", preferredStyle: .actionSheet)
        let index = Languages.sourceLanguages.firstIndex(of: userDefaults.languagePair.source) ?? 0
        
        alert.addPickerView(values: [ Languages.sourceLanguages.map{ $0.localName }], initialSelection: PickerViewViewController.Index(0, index)) { (_, _, index, values) in
            let value = values[index.column][index.row]
            let selectedLanguages = Languages.sourceLanguages.filter{ $0.localName == value }
            if let language = selectedLanguages.first {
                let newValue = language.rawValue
                let newLanguage = NLLanguage(newValue)
                alert.message = newLanguage.rawValue
                self.detectedLanguage = newLanguage
                
            }
        }
        
        alert.addAction(title: "OK", style: .cancel, handler: nil)
        alert.show {
            print("shown")
        }
    }
}
