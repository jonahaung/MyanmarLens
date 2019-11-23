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
    
    var languagePair = LanguagePair(.none, .none)
    
    private var text: String? {
        didSet {
            guard text != oldValue else { return }
            SoundManager.vibrate(vibration: .heavy)
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.lensManager(didGetResultText: self.text)
            }
        }
    }
    
    private var recognizedText: String? {
        didSet {
            guard recognizedText != oldValue else { return }
            SoundManager.vibrate(vibration: .medium)
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.lensManager(didGetRecognizedText: self.recognizedText)
            }
        }
    }
    var engineIsRunning = false {
        didSet {
            guard oldValue != engineIsRunning else { return }
            SoundManager.vibrate(vibration: .light)
            engine.recognitionIsActive = engineIsRunning
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.lensManager(engineIsRunning: self.engineIsRunning)
            }
        }
    }
    
    init() {
        setupEngine()
    }
    
    private func setupEngine() {
        engine = RealTimeEngine(swiftyTesseract: swiftyTesseract, desiredReliability: .tentative) { [weak self] recognizedString in
            guard let `self` = self else { return }
            if !recognizedString.isEmpty {
                self.engineIsRunning = false
                
                let clean = recognizedString.cleanUpMyanmarTexts()
                self.recognizedText = clean
                self.myMemoryTranslator.translate(text: clean, languagePair: self.languagePair) { [weak self] (result, err) in
                    guard let `self` = self else { return }
                    if let err = err {
                        self.text = err.localizedDescription.lowercased()
                        return
                    }
                    self.text = result
                }
            }
        }
        engine.recognitionIsActive = false
        engine.startPreview()
    }
    
    deinit {
        engineIsRunning = false
        print("Deinit: LensManager")
    }
}
