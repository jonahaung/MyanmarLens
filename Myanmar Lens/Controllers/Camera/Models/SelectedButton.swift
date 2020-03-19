//
//  SelectedButton.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 17/3/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import Foundation
enum SelectedButton: Int, CaseIterable {
    case none, textColor, flash, sound, zoom, videoQuality
    
    var label: String {
        switch self {
        case .textColor:
            return "Text Color"
        case .flash:
            return "Flash Light"
        case .sound:
            return "Speak Texts"
        case .zoom:
            return "Zoom"
        case .none:
            return ""
        case .videoQuality:
            return ""
        }
    }
}

extension SelectedButton: Hashable {
    
}
