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
    @Published var isAutoScan: Bool = userDefaults.isAutoScan {
        didSet {
            guard oldValue != isAutoScan else { return }
            userDefaults.isAutoScan = isAutoScan
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
            
            guard detectedLanguage != newValue else { return }
            
            if targetLanguage == newValue {
                targetLanguage = userDefaults.sourceLanguage
            }
            userDefaults.sourceLanguage = newValue
            DispatchQueue.main.safeAsync {
                self.objectWillChange.send()
            }
        }
    }
    
    var targetLanguage: NLLanguage {
        get {
            return userDefaults.targetLanguage
        }
        set {
            isStable = true
            guard targetLanguage != newValue else { return }
            userDefaults.targetLanguage = newValue
            DispatchQueue.main.safeAsync {
                self.objectWillChange.send()
            }
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
    var currentID: UUID?
    
    private let videoService: VideoService
    private let ocrService: OcrService
    private let boxService: BoxService
    private let translateService: TranslateService
   
    private let tracker: ObjectTracker<Int> = ObjectTracker(reliability: .tentative)
    private var isStable = false
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
        fps = videoService.fps
        videoService.start {[weak self] in
            DispatchQueue.main.safeAsync {
                self?.subjectAreaDidChange()
            }
        }
        
    }
    
    deinit {
        videoService.captureSession.stopRunning()
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        if device.torchMode == .on {
            toggleFlash()
        }
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
            reset()
        } else {
            if let id = currentID {
                self.showLoading = true
                videoService.stop {[weak self] in
                    guard let self = self else { return }
                    self.ocrService.capture(id: id)
                }
            }
            
        }
    }
    
    func reset() {
        fps = 3
        boxService.reset()
        overlayView.image = nil
        overlayView.zoomGestureController.image = nil
        showLoading = false
        displayingResults = false
        isStable = false
        tracker.resetAll()
        ocrService.reset()
        overlayView.apply(nil)
        videoService.start()
        
    }
    @objc private func subjectAreaDidChange() {
        
        guard !displayingResults else {
            return
        }
        
        do {
            try CaptureSession.current.resetFocusToAuto()
            fps = 3
            isStable = false
            tracker.resetAll()
            overlayView.apply(nil)
            ocrService.reset()
        } catch {
            let error = ImageScannerControllerError.inputDevice
            print(error)
            return
        }
    }
}



// OCR Serviece
extension ServiceManager: OcrServiceDelegate {
    
    func ocrService(_ service: OcrService, didOutput image: UIImage, with sourceLanguage: NLLanguage) {
        overlayView.image = image
        detectedLanguage = sourceLanguage
        overlayView.flashToBlack()
        overlayView.quadView.isStable = true
        displayingResults = true
    }
    
    
    func ocrService(_ service: OcrService, didCapture quad: Quadrilateral?, lastQuad: Quadrilateral?, isStable: Bool) {
        guard !displayingResults else { return }
        currentID = quad?.id
        self.isStable = isStable
       
        overlayView.apply(quad, isStable: isStable)
        if let parameter = quad?.perimeter {
             fps = 1
            let rounded = Int(round(10 * parameter))
            tracker.logFrame(objects: [rounded])
            if let best = tracker.bestString {
                self.didTapActionButton()
            }
        } else {
            reset()
        }
//        rectangleFunnel.add(quad?.applying(self.overlayView.videoPreviewLayer.layerTransform), currentlyDisplayedRectangle: lastQuad) {[weak self] (result, stableQuad) in
//            if result == .showAndAutoScan {
//                DispatchQueue.main.async {
//                    guard let self = self, !self.displayingResults else { return }
//                    self.overlayView.apply(stableQuad, isStable: true)
//                    self.didTapActionButton()
//                }
//            }
//        }
    }
    
    func ocrService(_ service: OcrService, didFailedCapture quad: Quadrilateral?) {
        reset()
        tracker.resetAll()
    }
    
    func ocrService(_ service: OcrService, didGetStableTextRects textRects: [TextRect]) {
        translateService.handle(textRects: textRects)
    }
}
// Box Serviece
extension ServiceManager: TranslateServiceDelegate {
    func translateService(_ service: TranslateService, didFinishTranslation textRects: [TextRect]) {
        guard displayingResults else { return }
        boxService.handle(textRects)
        showLoading = false
        SoundManager.vibrate(vibration: .light)
        
    }
}

// Overlay View
extension ServiceManager: OverlayViewDelegate {
    func overlayView(didTapScreen view: OverlayView) {
        reset()
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
    
    // Skew
    func didTapSkew() {
        overlayView.quadView.editable.toggle()
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
        alert.show()
    }
}
