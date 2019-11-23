//
//  Language.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 23/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation

enum Language: String, CaseIterable {
    case my, en, zh, ta, ko, ja, th
    
    var description: String {
        switch self {
        case .my:
            return "Myanmar"
        case .en:
            return "English"
        case .zh:
            return "China"
        case .ta:
            return "Tamil"
        case .ko:
            return "Korea"
        case .ja:
            return "Japan"
        case .th:
            return "Thailand"
        }
    }
    
    static var all = Language.allCases
}
