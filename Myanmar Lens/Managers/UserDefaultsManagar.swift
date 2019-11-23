//
//  UserDefaultsManagar.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 24/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation

let userDefaults = UserDefaultsManager()

final class UserDefaultsManager {
    
    fileprivate let defaults = UserDefaults.standard
    
    let toLanguage = "toLanguage"
    
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
        updateObject(for: toLanguage, with: Language.en.rawValue)
     }
    
    var language: Language {
        if let x = currentStringObjectState(for: toLanguage), let language = Language(rawValue: x) {
            return language
        }
        updateObject(for: toLanguage, with: Language.en.rawValue)
        return .en
    }
}

