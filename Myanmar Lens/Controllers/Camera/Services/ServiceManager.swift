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
    
    let videoService: VideoService = VideoService()
    let ocrService: OcrService
    let boxService: BoxService
    let overlayView: OverlayView
    
    private let queue = DispatchQueue(label: "com.jonahaung.ServiceManager", qos: .userInitiated)
    
    private let translateService = TranslateService()
    
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
        boxService = BoxService(_overlayView: overlayView)
        ocrService = OcrService(_overlayView: overlayView)
        translateService.delegate = self
        ocrService.delegate = self
        videoService.configure(layer: overlayView.videoPreviewLayer)
        updateLanguagePair()
        
    }
    
    
    func configure() {
        queue.async {[weak self] in
            guard let self = self else { return }
            self.videoService.captureSession?.startRunning()
            self.videoService.videoServiceDelegate = self.ocrService
        }
        
    }
    
    func stop() {
        
        videoService.captureSession?.stopRunning()
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
        
        Async.utility {[weak self] in
            guard let self = self else { return }
             self.translateService.handle(textRects: textRects)
        }.main {[weak self] in
            guard let self = self else { return }
            if self.isRepeat {
                service.isBusy = false
                service.semaphore.signal()
            }else {
                self.isStopped = true
            }
        }
    }
}

extension ServiceManager: TranslateServiceDelegate {
    
    
    func translateService(_ service: TranslateService, didFinishTranslation translateTextRects: [TranslateTextRect]) {
        
        self.boxService.handle(translateTextRects)
        
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
        let lp = userDefaults.languagePair
        let isMyanamr = lp.source == .burmese
        ocrService.isMyanmar = isMyanamr
        videoService.isMyanmar = isMyanamr
        source = lp.source.localName
        target = lp.target.localName
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
    
}
