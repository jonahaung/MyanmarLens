//
//  MyanmaLensManager.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 23/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation
import SwiftyTesseract
import SwiftyTesseractRTE

protocol MyanmaLensManagerDelegate: class {
    func lensManager(didGetResultText text: String?)
    func lensManager(didGetRecognizedText text: String?)
    func lensManager(engineIsRunning isRunning: Bool)
}

final class MyanmaLensManager {
    
    weak var delegate: MyanmaLensManagerDelegate?
    
    var engine: RealTimeEngine!
    private lazy var swiftyTesseract = SwiftyTesseract(language: .burmese)
    private lazy var myMemoryTranslator = MyMemoryTranslation.shared
    
    var languagePair = LanguagePair(.my, .my)
    
    private var text: String? {
        didSet {
            guard text != oldValue else { return }
            
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                SoundManager.vibrate(vibration: .success)
                self.delegate?.lensManager(didGetResultText: self.text)
            }
        }
    }
    
    private var recognizedText: String? {
        didSet {
            guard recognizedText != oldValue, let recognizedText = self.recognizedText, !recognizedText.isEmpty else { return }
            engineIsRunning = false
            let clean = recognizedText.cleanUpMyanmarTexts()
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                 SoundManager.vibrate(vibration: .success)
                self.delegate?.lensManager(didGetRecognizedText: clean)
            }
            if clean.isEmpty { return }
            self.myMemoryTranslator.translate(text: clean, languagePair: self.languagePair) { [weak self] (result, err) in
                guard let `self` = self else { return }
                if let err = err {
                    print(err.localizedDescription)
                    self.text = "no translations"
                    return
                }
                self.text = result
            }
        }
    }
    var engineIsRunning = false {
        didSet {
            guard oldValue != engineIsRunning else { return }
            
            engine.recognitionIsActive = engineIsRunning
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                SoundManager.playSound(tone: .Tock)
                self.delegate?.lensManager(engineIsRunning: self.engineIsRunning)
            }
        }
    }
    func reset() {
        recognizedText = " "
        text = "Press and hold the ● bottom to start"
    }
    
    init() {
        setupEngine()
    }
    
    private func setupEngine() {
    
        engine = RealTimeEngine(swiftyTesseract: swiftyTesseract, desiredReliability: .tentative) { [weak self] recognizedString in
            guard let `self` = self else { return }
            self.recognizedText = recognizedString
        }
        engine.recognitionIsActive = false
        engine.startPreview()
        engine.cameraQuality = .inputPriority
    }
    
    deinit {
        engineIsRunning = false
        print("Deinit: LensManager")
    }
}
