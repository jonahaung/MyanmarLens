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

enum CameraStage {
    case Start, Stop, Initial
}


class ServiceManager: ObservableObject {
   
    @Published var zoom: CGFloat = 0 {
        willSet {
            videoService.sliderValueDidChange(Float(zoom/20))
        }
    }
    
    var languagePair: LanguagePair = userDefaults.languagePair {
        didSet {
            guard oldValue != self.languagePair else { return }
            userDefaults.languagePair = self.languagePair
            let isMyanamr = languagePair.source == .burmese
            ocrService.isMyanmar = isMyanamr
            objectWillChange.send()
        }
    }
    
    @Published var showLoading: Bool = false {
        willSet {
            objectWillChange.send()
        }
    }
    @Published var touchLightIsOn: Bool = false {
        willSet {
            objectWillChange.send()
        }
    }
    @Published var isBlackAndWhite: Bool = userDefaults.isBlackAndWhite {
        didSet {
            userDefaults.isBlackAndWhite = self.isBlackAndWhite
            SoundManager.playSound(tone: .Typing)
            objectWillChange.send()
        }
        
    }
    private let videoService: VideoService
    private let ocrService: OcrService
    private let boxService: BoxService
    private let translateService: TranslateService
    let overlayView: OverlayView
    
    var stage: CameraStage = .Initial {
        didSet {
            guard oldValue != self.stage else { return }
            self.updateStage(stage: self.stage)
        }
    }
    
    init() {
        overlayView = OverlayView()
        videoService = VideoService()
        translateService = TranslateService()
        boxService = BoxService(_overlayView: overlayView)
        ocrService = OcrService(_overlayView: overlayView)
        videoService.configure(layer: overlayView.videoPreviewLayer)
        updateLanguagePair()
    }
    
    func configure() {
        videoService.captureSession.startRunning()
        translateService.delegate = self
        ocrService.delegate = self
        videoService.videoServiceDelegate = ocrService
    }
    
    func stop() {
        self.stage = .Stop
    }
    
    deinit {
        stop()
        print("Service Manager")
    }
}
// OCR Serviece
extension ServiceManager: OcrServiceDelegate {
    func ocrService(_ service: OcrService, didGetStable image: UIImage?) {
        DispatchQueue.main.async {
            self.stage = .Stop
            self.overlayView.imageView.image = image
            self.showLoading = true
        }
    }

    func ocrService(_ service: OcrService, didGetStableTextRects textRects: [TextRect]) {
        Async.main {
            self.boxService.handle(textRects)
            self.showLoading = false
//            self.overlayView.imageView.image = nil
//            self.boxService.clearlayers()
//            self.translateService.handle(textRects: textRects)
        }
        
    }
}
// Box Serviece
extension ServiceManager: TranslateServiceDelegate {
    func translateService(_ service: TranslateService, didFinishTranslation textRects: [TextRect]) {
        self.boxService.handle(textRects)
        self.showLoading = false
    }
}

// Others

extension ServiceManager {
    // Language Pair
    func toggleLanguagePair() {
        let languagePair = self.languagePair
        let new = LanguagePair(source: languagePair.target, target: languagePair.source)
        userDefaults.languagePair = new
        self.languagePair = new
        SoundManager.playSound(tone: .Typing)
    }
    private func updateLanguagePair() {
        languagePair = userDefaults.languagePair
        
    }
    
    // Flash Light
    func didTapFlashLight() {
        SoundManager.playSound(tone: .Tock)
        
        guard let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch else { return }
        let isOn = device.torchMode == .on
        do {
            try device.lockForConfiguration()
            
            device.torchMode = isOn ? .off : .on
            device.unlockForConfiguration()
            self.touchLightIsOn = !isOn
        } catch {
            print("Torch could not be used")
        }
        SoundManager.playSound(tone: .Typing)
    }
    
    // Action
    func didTapActionButton() {
        if showLoading {
            return 
        }
        
        if overlayView.imageView.image != nil {
            overlayView.imageView.image = nil
            boxService.clearlayers()
            return
        }
        
        switch stage {
        case .Initial:
            stage = .Start
        case .Stop:
            stage = .Start
        case .Start:
            stage = .Stop
        }
    }
    
    private func updateStage(stage: CameraStage) {
        switch stage {
        case .Start:
            ocrService.isMyanmar = userDefaults.languagePair.source == .burmese
            boxService.clearlayers()
            videoService.canOutputBuffer = true
            overlayView.imageView.image = nil
            self.ocrService.start()
             SoundManager.vibrate(vibration: .selection)
            SoundManager.playSound(tone: .Tock)

        case .Stop:
            videoService.canOutputBuffer = false
            ocrService.stop()
            SoundManager.vibrate(vibration: .selection)
            
        case .Initial:
            break
        }
    }
    
}

// Language
extension ServiceManager {
    func didTapTargetLanguage() {
        SoundManager.vibrate(vibration: .medium)
        let alert = UIAlertController(title: "Target Language", message: "Pls select one of the following target languages", preferredStyle: .actionSheet)
        let index = Languages.targetLanguages.firstIndex(of: userDefaults.languagePair.target) ?? 1
        var selected: String?
        
        let okAction = UIAlertAction(title: "Update Language", style: .default) { _ in
            if let selected = selected {
                let selectedLanguages = Languages.targetLanguages.filter{ $0.localName == selected }
                if let language = selectedLanguages.first {
                    let newValue = language.rawValue
                    let newlanguagePair = LanguagePair(source: userDefaults.languagePair.source, target: NLLanguage(newValue))
                    self.languagePair = newlanguagePair
                }
            }
        }
        okAction.isEnabled = false
        alert.addPickerView(values: [ Languages.targetLanguages.map{ $0.localName }], initialSelection: PickerViewViewController.Index(0, index)) { (_, _, index, values) in
            let value = values[index.column][index.row]
            let isValid = value != userDefaults.languagePair.source.localName
            okAction.isEnabled = isValid
            if isValid {
                alert.title = value
                alert.message = "Press Update to select this language"
                selected = value
            } else {
                SoundManager.vibrate(vibration: .error)
                alert.title = "Not Allowed!"
                alert.message = "Source Language and Target Language should not be the same..."
                selected = nil
            }
        }
        alert.addAction(okAction)
        alert.addCancelAction()
        alert.show()
    }
    
    func didTapSourceLanguage() {
        SoundManager.vibrate(vibration: .medium)
        let alert = UIAlertController(title: "Source Language", message: "Pls select one of the following source languages", preferredStyle: .actionSheet)
        let index = Languages.sourceLanguages.firstIndex(of: userDefaults.languagePair.source) ?? 0
        var selected: String?
        alert.addAction(title: "Switch Language") { _ in
            self.toggleLanguagePair()
        }
        let okAction = UIAlertAction(title: "Update Language", style: .default) { _ in
            if let selected = selected {
                let selectedLanguages = Languages.sourceLanguages.filter{ $0.localName == selected }
                if let language = selectedLanguages.first {
                    let newValue = language.rawValue
                    let newlanguagePair = LanguagePair(source: NLLanguage(newValue), target: userDefaults.languagePair.target)
                    self.languagePair = newlanguagePair
                   
                }
            }
        }
        okAction.isEnabled = false
        alert.addPickerView(values: [ Languages.sourceLanguages.map{ $0.localName }], initialSelection: PickerViewViewController.Index(0, index)) { (_, _, index, values) in
            let value = values[index.column][index.row]
            let isValid = value != userDefaults.languagePair.target.localName
            okAction.isEnabled = isValid
            if isValid {
                alert.title = value
                alert.message = "Press Update to select this language"
                selected = value
            } else {
                SoundManager.vibrate(vibration: .error)
                alert.title = "Not Allowed!"
                alert.message = "Source Language and Target Language should not be the same..."
                selected = nil
            }
        }
        alert.addAction(okAction)
        alert.addCancelAction()
        alert.show()
    }
}
