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
    private let canSpeakResults = "canSpeakResults"
    private let hasOpenedBefore = "hasOpenedBefore"
    
    var language: NLLanguage {
        get {
            if let x = defaults.string(forKey: toLanguage) {
                return NLLanguage(rawValue: x)
            }
            updateObject(for: toLanguage, with: NLLanguage.english.rawValue)
            return .english
        }
        set {
            updateObject(for: toLanguage, with: newValue.rawValue)
            SoundManager.playSound(tone: .Typing)
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
            language = newValue == .english ? .burmese : .english
            updateObject(for: fromLanguage, with: newValue.rawValue)
        }
        
    }
    
    var languagePair: LanguagePair {
        get {
            return (sourceLanguage, language)
        }
        set {
            guard newValue.0 != newValue.1 else { return }
            sourceLanguage = newValue.0
            language = newValue.1
        }
    }
    
    func toggleSourceLanguage() {
        sourceLanguage = sourceLanguage == .burmese ? .english : .burmese
        SoundManager.playSound(tone: .Tock)
    }
    
    var canSpeak: Bool {
        get {
            return defaults.bool(forKey: canSpeakResults)
        }
        set {
            updateObject(for: canSpeakResults, with: newValue)
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
