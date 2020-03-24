//
//  StartUpManager.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 27/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation

struct StartUpManager {
    
    static func checkVersion() {
        if !userDefaults.openedBefore {
            userDefaults.openedBefore = true
            userDefaults.isAutoScan = true
            userDefaults.isLanguageDetectionEnabled = true
        }
    }
}
