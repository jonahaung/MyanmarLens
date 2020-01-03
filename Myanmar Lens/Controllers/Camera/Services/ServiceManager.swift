//
//  Service.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 28/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation
import AVKit
import Vision
import SwiftUI
import Combine

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
    @Published var progress: CGFloat = 0 {
        willSet {
            objectWillChange.send()
        }
    }
    @Published var image: UIImage = UIImage() {
        willSet {
            objectWillChange.send()
        }
    }
    @Published var zoom: CGFloat = 5 {
        willSet {
            SoundManager.vibrate(vibration: .medium)
            videoService.sliderValueDidChange(Float(zoom/20))
            objectWillChange.send()
        }
    }
    
    var selectedNSTModel: NSTDemoModel = .starryNight
    
    let videoService: VideoService = VideoService()
    let ocrService: OcrService
    let boxService: BoxService
    let overlayView: OverlayView
    private let queue = DispatchQueue(label: "ServiceManager.queue", attributes: .concurrent)

    private let translateService = TranslateService()
    @Published var isStopped: Bool = true {
        didSet {
            guard oldValue != self.isStopped else { return }
            videoService.canOutputBuffer = !isStopped
            isStopped ? ocrService.stop() : ocrService.start()
        }
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            
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
        queue.async {
            self.videoService.captureSession?.startRunning()
            self.videoService.videoServiceDelegate = self
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
    
    func ocrService(_ service: OcrService, didUpdate progress: CGFloat) {
        Async.main {
            print(progress)
            self.progress = progress
        }
    }
    
    
    
    func ocrService(_ service: OcrService, didUpdate box: Box) {
        Async.main {[weak self] in
            guard let self = self else { return }
            self.overlayView.handle(highlightLayer: box)
        }
    }
    
    func ocrService(_ service: OcrService, didGetTextRects textRects: [TextRect]) {
        Async.main{[weak self] in
            guard let self = self else { return }
            self.boxService.handle(textRects)
            
        }
    }
    func ocrService(_ service: OcrService, didGetStableTextRects textRects: [TextRect]) {
        
        
        Async.main{[weak self] in
        guard let self = self else { return }
//           self.isStopped = true
//             self.boxService.handle(textRects)
             self.translateService.handle(textRects: textRects)
        }
    }
}

extension ServiceManager: TranslateServiceDelegate {
    
    func translateService(_ service: TranslateService, didFinishTranslation translateTextRects: [TranslateTextRect]) {
        DispatchQueue.main.async {
            self.overlayView.highlightLayer.lineWidth = 0
            self.boxService.handle(translateTextRects)
            self.ocrService.isBusy = false
        }
    }
}

extension ServiceManager: VideoServiceDelegate {
    
    func videoService(_ service: VideoService, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        
        if let buffer = pixelBuffer {
            
            ocrService.handle(pixelBuffer: buffer)
        }
    }
}


// Others

extension ServiceManager {
    
    func didTapActionButton() {
        self.overlayView.highlightLayer.lineWidth = 1.5
        SoundManager.vibrate(vibration: .heavy)
        self.isStopped.toggle()
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
    func getPercentage(value: CGFloat) -> String {
           let intValue = Int(ceil(progress * 100))
           if intValue == 0 {
               return String()
           }
           return "\(intValue) %"
       }

       func didTapFlashLight() {
           SoundManager.playSound(tone: .Tock)
        DispatchQueue.global(qos: .background).async {
            if let cg = self.ocrService.getCurrentCgImage() {
                let image = UIImage(cgImage: cg)
                
                do {
                    let modelProvider = try self.selectedNSTModel.modelProvider()
                    let outputImage = try modelProvider.prediction(inputImage: image)
                    Async.main {
                        self.image = outputImage
                        UIImageWriteToSavedPhotosAlbum(outputImage, self, nil, nil)
                    }
                    
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
//           guard let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch else { return }
//           let isOn = device.torchMode == .on
//           do {
//               try device.lockForConfiguration()
//
//               device.torchMode = isOn ? .off : .on
//               device.unlockForConfiguration()
//               let onImage = UIImage(systemName: "lightbulb.fill")
//               let offImage = UIImage(systemName: "lightbulb.slash.fill")
//           } catch {
//               print("Torch could not be used")
//           }
           
       }
       
       func handleZoom() {
           
       }
}
