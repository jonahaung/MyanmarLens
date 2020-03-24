//
//  UserDefaultsManagar.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 24/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation
import NaturalLanguage

let userDefaults = UserDefaultsManager()

final class UserDefaultsManager {
    
    private let defaults = UserDefaults.standard
    
    private let toLanguage = "toLanguage"
    private let fromLanguage = "fromLanguage"
    let hasDoneEULA = "hasDoneEULA"
    private let _autoDeteLanguage = "autoDeteLanguage"
    private let _isAutoScan = "isAutoScan"
    private let _isLanguageDetectionEnabled = "isLanguageDetectionEnabled"
    private let hasOpenedBefore = "hasOpenedBefore"
    private let _flashLightOn = "flashLightOn"
    private let _videoQuality = "videoQuality"
    private let _textTheme = "textTheme"
    
    var targetLanguage: NLLanguage {
        get {
            if let x = defaults.string(forKey: toLanguage) {
                return NLLanguage(rawValue: x)
            }
            updateObject(for: toLanguage, with: NLLanguage.english.rawValue)
            return .english
        }
        set {
            updateObject(for: toLanguage, with: newValue.rawValue)
            SoundManager.playSound(tone: .Tock)
        }
        
    }
    
    var sourceLanguage: NLLanguage {
        get {
            if let x = defaults.string(forKey: fromLanguage) {
                return NLLanguage(rawValue: x)
            }
            updateObject(for: fromLanguage, with: NLLanguage.burmese.rawValue)
            return .burmese
        }
        set {
            updateObject(for: fromLanguage, with: newValue.rawValue)
        }
        
    }
    
    var languagePair: LanguagePair {
        get {
            return LanguagePair(source: sourceLanguage, target: targetLanguage)
        }
        set {
          
            sourceLanguage = newValue.source
            targetLanguage = newValue.target
        }
    }

    var isLanguageDetectionEnabled: Bool {
        get {
            return defaults.bool(forKey: _isLanguageDetectionEnabled)
        }
        set {
            updateObject(for: _isLanguageDetectionEnabled, with: newValue)
            SoundManager.playSound(tone: .Typing)
        }
    }
    var isAutoScan: Bool {
        get {
            return defaults.bool(forKey: _isAutoScan)
        }
        set {
            updateObject(for: _isAutoScan, with: newValue)
            SoundManager.playSound(tone: .Typing)
        }
    }
    
    var flashLightOn: Bool {
        get {
            return defaults.bool(forKey: _flashLightOn)
        }
        set {
            updateObject(for: _flashLightOn, with: newValue)
            SoundManager.playSound(tone: .Typing)
        }
    }
    var openedBefore: Bool {
        get {
            return defaults.bool(forKey: hasOpenedBefore)
        }
        set {
            updateObject(for: hasOpenedBefore, with: newValue)
        }
    }

    var videoQuality: Int {
        get {
            return defaults.integer(forKey: _videoQuality)
        }
        set {
            updateObject(for: _videoQuality, with: newValue)
            SoundManager.playSound(tone: .Tock)
        }
    }
   
    var textTheme: TextTheme {
        get {
            let x = defaults.integer(forKey: _textTheme)
            return TextTheme(rawValue: x) ?? .Adaptive
            
        }
        set {
            let x = newValue.rawValue
            updateObject(for: _textTheme, with: x)
        }
    }
}

extension UserDefaultsManager {
    
    func updateObject(for key: String, with data: Any?) {
         defaults.set(data, forKey: key)
         defaults.synchronize()
     }
     
     //removing
     func removeObject(for key: String) {
         defaults.removeObject(forKey: key)
     }
    
     func currentStringObjectState(for key: String) -> String? {
         return defaults.string(forKey: key)
     }
     
     func currentIntObjectState(for key: String) -> Int? {
         return defaults.integer(forKey: key)
     }
     
     func currentBoolObjectState(for key: String) -> Bool {
         return defaults.bool(forKey: key)
     }
     
     func currentDoubleObject(for key: String) -> Double? {
         return defaults.double(forKey: key)
     }
     func currentFloatObject(for key: String) -> Float? {
         return defaults.float(forKey: key)
     }
    
     func resetToDefaults() {
        updateObject(for: toLanguage, with: NLLanguage.english.rawValue)
     }
    
}
