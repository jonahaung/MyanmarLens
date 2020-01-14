//
//  Service.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 28/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation
import AVKit
import SwiftUI
import Combine
import NaturalLanguage

enum CameraStage {
    case Start, Stop, Initial
}
class ServiceManager: ObservableObject {

    
    @Published var source: String = "" {
        willSet {
            objectWillChange.send()
        }
    }
    
    @Published var target: String = "" {
        willSet {
            objectWillChange.send()
        }
    }
    
    @Published var zoom: CGFloat = 0 {
        willSet {
            videoService.sliderValueDidChange(Float(zoom/20))
        }
    }
    
    @Published var infoText: String = "Press Circle-Button and point the camera at the texts" {
        willSet {
            objectWillChange.send()
        }
    }
    
    var languagePair: LanguagePair = LanguagePair(.burmese, .burmese) {
        didSet {
            guard oldValue != self.languagePair else { return }
            let isMyanamr = languagePair.source == .burmese
            ocrService.isMyanmar = isMyanamr
            source = languagePair.source.localName
            target = languagePair.target.localName
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
    
    @Published var showLoading: Bool = false {
        willSet {
            objectWillChange.send()
        }
    }
    
    init() {
        overlayView = OverlayView()
        videoService = VideoService()
        translateService = TranslateService()
        boxService = BoxService(_overlayView: overlayView)
        ocrService = OcrService(_overlayView: overlayView)
        translateService.delegate = self
        ocrService.delegate = self
        videoService.videoServiceDelegate = ocrService
        videoService.configure(layer: overlayView.videoPreviewLayer)
        updateLanguagePair()
    }
    
    func configure() {
        videoService.sessionQueue.async {[weak self] in
            guard let self = self else { return }
            self.videoService.sessionQueue.async {
                self.videoService.captureSession?.startRunning()
            }
        }
    }
    
    func stop() {
        self.stage = .Stop
    }
    
    deinit {
        stop()
        print("Service Manager")
    }
}

extension ServiceManager: OcrServiceDelegate {
    func ocrService(_ service: OcrService, didUpdate rect: CGRect) {
        DispatchQueue.main.async {
            self.overlayView.highlightLayerFrame = rect
        }
    }
    
    func ocrService(_ service: OcrService, didGetStableTextRects textRects: [TextRect]) {
        stage = .Stop
        overlayView.heighlightLayer.lineWidth = 0
        translateService.handle(textRects: textRects)
    }
}

extension ServiceManager: TranslateServiceDelegate {
    func translateService(_ service: TranslateService, didFinishTranslation textRects: [TextRect]) {
        self.boxService.handle(textRects)
        
    }
}

// Others

extension ServiceManager {
    
    func didTapActionButton() {
        
        switch stage {
        case .Initial:
            stage = .Start
        case .Stop:
            stage = .Start
        case .Start:
            stage = .Stop
        }
    }

    
    func toggleLanguagePair() {
        let languagePair = userDefaults.languagePair
        let new = LanguagePair(languagePair.target, languagePair.source)
        userDefaults.languagePair = new
        updateLanguagePair()
        SoundManager.playSound(tone: .Typing)
    }
    private func updateLanguagePair() {
        languagePair = userDefaults.languagePair
        
    }
    
    func didTapFlashLight() {
        SoundManager.playSound(tone: .Tock)
        
        guard let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch else { return }
        let isOn = device.torchMode == .on
        do {
            try device.lockForConfiguration()
            
            device.torchMode = isOn ? .off : .on
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used")
        }
        SoundManager.playSound(tone: .Typing)
    }
    
    private func updateStage(stage: CameraStage) {
        switch stage {
        case .Start:
            self.videoService.start {
                DispatchQueue.main.async {
                     SoundManager.playSound(tone: .Tock)
                    self.boxService.clearlayers()
                    self.infoText = "Please Hold Still"
                    self.showLoading = true
                    self.ocrService.start()
                     SoundManager.vibrate(vibration: .selection)
                }
            }
        case .Stop:
            self.videoService.stop {
                DispatchQueue.main.async {
                    SoundManager.playSound(tone: .Tock)
                    self.showLoading = false
                    self.ocrService.stop()
                    self.infoText = "Press Circle-Button and point the camera at the texts"
                    SoundManager.vibrate(vibration: .selection)
                }
            }
        case .Initial:
            break
        }
    }
    
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
                    userDefaults.languagePair = newlanguagePair
                    self.target = newlanguagePair.target.localName
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
                    userDefaults.languagePair = newlanguagePair
                    self.source = newlanguagePair.source.localName
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
