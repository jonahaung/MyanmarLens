//
//  ViewController.swift
//  MathSolver
//
//  Created by Khoa Pham on 26.06.2018.
//  Copyright © 2018 onmyway133. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    enum State {
        case tracking
        case stopped
        case paused
        case resume
    }
  
    private let cameraController = CameraController()
    private let visionService = VisionService()
    private lazy var boxService = BoxService(_overlayView: OverlayView())
    private let translateService = TranslateService()
    
    private let queue: OperationQueue = {
        $0.maxConcurrentOperationCount = 1
        $0.qualityOfService = .userInitiated
        return $0
    }(OperationQueue())
    
    private var isRepeat = userDefaults.isRepeat
    private var isFirstTime = true
    var languagePair = LanguagePair(.undetermined, .undetermined) {
        didSet {
            updateLanguagePair()
        }
    }
    
    var state: State = .stopped {
        didSet {
            updateStage()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = [.top, .bottom]
        addDefaultBackgroundImageView()
        let themeColor = UIColor.white
        navigationController?.navigationBar.tintColor = themeColor
        navigationController?.toolbar.tintColor = themeColor
        cameraController.setTheme(color: themeColor)
        navigationItem.rightBarButtonItems = [cameraController.targetLanguage, UIBarButtonItem(customView: UIImageView(image: UIImage(systemName: "chevron.right.2"))), cameraController.sourceLanguage]
        navigationController?.setToolbarHidden(false, animated: false)
        setToolbarItems(cameraController.getToolbarItems(), animated: false)
        
        
        add(childController: cameraController)
        cameraController.view.frame = view.bounds

        cameraController.videoManager.captureSession.startRunning()
//        boxService.previewView = cameraController.overlayView
        cameraController.overlayView.delegate = self
        visionService.delegate = self
        translateService.delegate = self
        cameraController.videoManager.delegate = visionService
         languagePair = userDefaults.languagePair
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        state = .stopped
        visionService.reset()
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
        navigationController?.navigationBar.tintColor = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        visionService.regionOfInterest = cameraController.overlayView.regionOfInterest
        
       
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirstTime {
            isFirstTime = false
            var insets = view.safeAreaInsets
            insets.bottom = insets.top
            let length = view.bounds.width * 0.8
            let size = CGSize(width: length, height: CGFloat(userDefaults.regionOfInterestHeght))
            let defaultROI = size.bma_rect(inContainer: view.bounds, xAlignament: .center, yAlignment: .center, dy: 10)
//            cameraController.overlayView.setROI(defaultROI)
            
            cameraController.safeAreaInsets = insets
            visionService.regionOfInterest = defaultROI
            visionService.parentBounds = cameraController.overlayView.bounds
            cameraController.delegate = self
        }
        
    }
    
    deinit {
        print("Deinit")
    }
}
// Vision
extension CameraViewController: VisionServiceDelegate {

    func visionService(_ service: VisionService, didUpdate box: Box) {
        DispatchQueue.main.async {
            
        }
    }
    
    func visionService(_ service: VisionService, didGetTextRects textRects: [TextRect]) {
        DispatchQueue.main.async {
            self.boxService.handle(textRects)
        }
    }
    
    func visionService(_ service: VisionService, didGetStableTextRects textRects: [TextRect]) {
        state = .stopped
        DispatchQueue.main.async {
            self.boxService.handle(textRects)
            self.translateService.handle(textRects: textRects)
        }
    }
}


// Translate

extension CameraViewController: TranslateServiceDelegate {
    
    func translateService(_ service: TranslateService, didFinishTranslation translateTextRects: [TranslateTextRect]) {
        state = .stopped
        DispatchQueue.main.async {
            SoundManager.playSound(tone: .Tock)
            
            self.boxService.handle(translateTextRects.map{ TextRect($0.translatedText ?? "", $0.textRect.rect)})
        }
    }
}

// Camera
extension CameraViewController: CameraControllerDelegate, PreviewCiewDelegate {
    
    func previewView(_ view: PreviewView, gestureStageChanges isStart: Bool) {
//        boxService.reset()
        visionService.stop()
        if !isStart {
            visionService.regionOfInterest = view.regionOfInterest
            userDefaults.regionOfInterestHeght = Float(view.regionOfInterest.height)
            visionService.reset()
        }
    }

    var safeAreaInsets: UIEdgeInsets? {
        var insets = view.safeAreaInsets
        insets.bottom += cameraController.actionButton.bounds.height
        return insets
    }

    func cameraController(_ controller: CameraController, didUpdateLanguage pair: LanguagePair) {
        languagePair = pair
    }

    func cameraController(_ controller: CameraController, didChangRepeatState isRepeat: Bool) {
        self.isRepeat = isRepeat
    }
    
    func previewView(_ view: PreviewView, didChangeRegionOfInterest rect: CGRect) {
        SoundManager.vibrate(vibration: .light)
    }
    
    func cameraController(didTapActionButton controller: CameraController) {
        SoundManager.playSound(tone: .Tock)
        queue.cancelAllOperations()
        state = state == .stopped ? .tracking : .stopped
    }
    
    private func updateLanguagePair() {
        visionService.isMyanmar = languagePair.0 == .burmese
        
        navigationItem.title = languagePair.0.localName
        cameraController.targetLanguage.title = languagePair.1.localName
        cameraController.sourceLanguage.title = languagePair.0.localName
    }
    
    private func updateStage() {
        switch state {
        case .stopped:
            queue.addOperation {[weak self] in
                guard let self = self else { return }
                self.visionService.stop()
                DispatchQueue.main.async {
                    self.navigationController?.setToolbarHidden(false, animated: true)
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                    self.cameraController.loading(isLoading: false)
                }
            }
        case .tracking:
            queue.addOperation {[weak self] in
                guard let self = self else { return }
                self.visionService.start()
                DispatchQueue.main.async {
                    self.navigationController?.setToolbarHidden(true, animated: true)
                    self.navigationController?.setNavigationBarHidden(true, animated: true)
                    self.cameraController.loading(isLoading: true)
//                    self.boxService.reset()
                }
            }
        case .paused:
            break
        //                semephore.wait()
        case .resume:
            break
            //                semephore.signal()
        }
    
    }
}
