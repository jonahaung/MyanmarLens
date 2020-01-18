//
//  UserSettings.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 17/1/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import Foundation

class UserSettings: ObservableObject {
    @Published var languagePair = userDefaults.languagePair {
        didSet {
            userDefaults.languagePair = languagePair
            objectWillChange.send()
        }
    }
    func toggleLanguagePari() {
        self.languagePair = LanguagePair(source: languagePair.target, target: languagePair.source)
    }
    
    @Published var isBlackAndWhite: Bool = userDefaults.isBlackAndWhite {
        didSet {
            userDefaults.isBlackAndWhite = self.isBlackAndWhite
            SoundManager.playSound(tone: .Typing)
            objectWillChange.send()
        }
    }
}
