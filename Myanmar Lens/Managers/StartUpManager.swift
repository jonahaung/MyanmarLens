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
            
        }
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let currentVersionNumber = Float(appVersion) {
            let oldVersionNumber = userDefaults.versionNumber
            if currentVersionNumber != oldVersionNumber {
                userDefaults.versionNumber = currentVersionNumber
                if PersistanceManager.shared.viewContext.deleteAllData(entityName: TranslatePair.description()) {
                    
                }
            }
        }
    }
}
