//
//  Setting.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 26/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation


enum Setting: CaseIterable {
    
    case DeviceSettings, ResetSettings, AboutDeveloper, ShareApp, PrivacyPolicy, ContactUs
    
    var description: String {
        switch self {
        case .DeviceSettings:
            return "Device Settings"
        case .ResetSettings:
            return "Reset Settings"
        case .AboutDeveloper:
            return "About Developer"
        case .ShareApp:
            return "Share App"
        case .PrivacyPolicy:
            return "Privacy Policy"
        case .ContactUs:
            return "Contact Us"
        }
    }
    
    var imageName: String {
        switch self {
        case .DeviceSettings:
            return "wrench"
        case .ResetSettings:
            return "house"
        case .AboutDeveloper:
            return "signature"
        case .ShareApp:
            return "arrowshape.turn.up.right"
        case .PrivacyPolicy:
            return "lock.shield"
        case .ContactUs:
            return "message"
        }
    }
    
    static let all = Setting.allCases
}
