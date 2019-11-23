//
//  Language.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 23/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation

enum Language: String {
    case my, en, none
    
    var description: String {
        switch self {
        case .my:
            return "Myanmar"
        case .en:
            return "English"
        case .none:
            return "Select Language"
        }
    }
}
