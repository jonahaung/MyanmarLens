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

class ServiceManager: ObservableObject {
    
    @Published var isRepeat : Bool = userDefaults.isRepeat {
        didSet {
            userDefaults.isRepeat = self.isRepeat
            dropDownMessageBar.show(text: "Auto-Repeat \(self.isRepeat ? "ON" : "Off")", duration: 3)
            objectWillChange.send()
        }
    }
    
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
            SoundManager.vibrate(vibration: .medium)
            videoService.sliderValueDidChange(Float(zoom/20))
            objectWillChange.send()
        }
    }
    
    var languagePair: LanguagePair = LanguagePair(.burmese, .burmese) {
        didSet {
            guard oldValue != self.languagePair else { return }
            let isMyanamr = languagePair.source == .burmese
            ocrService.isMyanmar = isMyanamr
            videoService.isMyanmar = isMyanamr
            source = languagePair.source.localName
            target = languagePair.target.localName
        }
    }
    
    private let videoService: VideoService
    private let ocrService: OcrService
    private let boxService: BoxService
    private let translateService: TranslateService
    let overlayView: OverlayView
    
    private let queue = DispatchQueue(label: "com.jonahaung.ServiceManager", qos: .userInitiated)
    
    
    @Published var isStopped: Bool = true {
        didSet {
            guard oldValue != self.isStopped else { return }
            videoService.canOutputBuffer = !isStopped
            videoService.isMyanmar = self.source == "Burmese"
            isStopped ? ocrService.stop() : ocrService.start()
            
        }
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
        videoService.sessionQueue.sync {[weak self] in
            guard let self = self else { return }
            self.videoService.captureSession?.startRunning()
            
        }
    }
    
    func stop() {
        self.videoService.captureSession?.stopRunning()
        
    }
    deinit {
        stop()
        print("Service Manager")
    }
}

extension ServiceManager: OcrServiceDelegate {
    
    func ocrService(_ service: OcrService, didUpdate box: Box) {
        Async.main {[weak self] in
            guard let self = self else { return }
            self.overlayView.handle(highlightLayer: box)
        }
    }
    
    func ocrService(_ service: OcrService, didGetStableTextRects textRects: [TextRect]) {
        
        translateService.handle(textRects: textRects)
    }
}

extension ServiceManager: TranslateServiceDelegate {
    func translateService(_ service: TranslateService, didFinishTranslation textRects: [TextRect]) {
        self.boxService.handle(textRects)
        self.ocrService.updateCache(textRects)
        if self.isRepeat {
            ocrService.semaphore.signal()
        }else {
            self.isStopped = true
        }
    }
}

// Others

extension ServiceManager {
    
    func didTapActionButton() {
        SoundManager.vibrate(vibration: .heavy)
        self.ocrService.stop()
        isStopped.toggle()
    }
    func toggleLanguagePair() {
        let languagePair = userDefaults.languagePair
        let new = LanguagePair(languagePair.target, languagePair.source)
        userDefaults.languagePair = new
        updateLanguagePair()
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
