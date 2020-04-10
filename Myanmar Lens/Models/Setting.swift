//
//  Setting.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 26/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation


enum Setting: CaseIterable {
    
    case DeviceSettings, ResetSettings, ShareApp, PrivacyPolicy, ContactUs, AboutDeveloper, RateApp
    
    var description: String {
        switch self {
        case .DeviceSettings:
            return "Device Settings"
        case .ResetSettings:
            return "Reset Settings"
        case .AboutDeveloper:
            return "App Developer"
        case .ShareApp:
            return "Share App"
        case .PrivacyPolicy:
            return "Privacy Policy"
        case .ContactUs:
            return "Contact Us"
        case .RateApp:
            return "Rate App"
        }
    }
    
    static let all = Setting.allCases
}
