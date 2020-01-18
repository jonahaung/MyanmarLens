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
    private let NumberOfTimePerRecognition = "NumberOfTimePerRecognition"
    private let canRepeat = "CanRepeat"
    private let regionOfInterestHeightt = "regionOfInterestHeightt"
    private let _isAttentionBased = "isAttentionBased"
    private let _displayResultsOnVideoView = "displayResultsOnVideoView"
    private let _isBlackAndWhite = "isBlackAndWhite"
    private var targetLanguage: NLLanguage {
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
    
    private var sourceLanguage: NLLanguage {
        get {
            if let x = defaults.string(forKey: fromLanguage) {
                return NLLanguage(rawValue: x)
            }
            updateObject(for: fromLanguage, with: NLLanguage.burmese.rawValue)
            return .burmese
        }
        set {
            targetLanguage = newValue == .english ? .burmese : .english
            updateObject(for: fromLanguage, with: newValue.rawValue)
        }
        
    }
    
    var languagePair: LanguagePair {
        get {
            return LanguagePair(source: sourceLanguage, target: targetLanguage)
        }
        set {
            guard newValue.source != newValue.target else { return }
            sourceLanguage = newValue.source
            targetLanguage = newValue.target
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
    var isRepeat: Bool {
        get {
            return defaults.bool(forKey: canRepeat)
        }
        set {
            updateObject(for: canRepeat, with: newValue)
            SoundManager.playSound(tone: .Typing)
        }
    }
    
    var isAttentionBased: Bool {
        get {
            return defaults.bool(forKey: _isAttentionBased)
        }
        set {
            updateObject(for: _isAttentionBased, with: newValue)
            SoundManager.playSound(tone: .Tock)
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

    var regionOfInterestHeght: Float {
        get {
            let value = defaults.float(forKey: regionOfInterestHeightt)
            return value == 0 ? 150 : value
        }
        set {
            updateObject(for: regionOfInterestHeightt, with: newValue)
        }
    }
    var displayResultsOnVideoView: Bool {
        get {
          
            return defaults.bool(forKey: _displayResultsOnVideoView)
        }
        set {
            updateObject(for: _displayResultsOnVideoView, with: newValue)
        }
    }
    var isBlackAndWhite: Bool {
        get {
          
            return defaults.bool(forKey: _isBlackAndWhite)
        }
        set {
            updateObject(for: _isBlackAndWhite, with: newValue)
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
