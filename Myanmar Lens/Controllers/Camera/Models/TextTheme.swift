//
//  TextTheme.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 15/3/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import Foundation

enum TextTheme: Int, CaseIterable {
    case Adaptive, BlackAndWhite
    
    var label: String {
        switch self {
        case .BlackAndWhite:
            return "Black"
        case .Adaptive:
            return "Adaptive"
        }
    }
    
    var iconName: String {
        switch self {
        case .BlackAndWhite:
            return "paintbrush"
        case .Adaptive:
            return "paintbrush.fill"
        }
    }
    
    static func toggle() {
        
    }
}
