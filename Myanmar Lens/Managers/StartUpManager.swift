//
//  StartUpManager.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 27/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation
import CoreData

struct StartUpManager {
    
    static func checkVersion() {
        if !userDefaults.openedBefore {
            userDefaults.openedBefore = true
            
        }
    }
}
