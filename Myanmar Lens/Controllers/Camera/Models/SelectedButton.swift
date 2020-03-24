//
//  SelectedButton.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 17/3/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import Foundation
enum SelectedButton: Int, CaseIterable {
    case none, textColor, zoom
    
    var label: String {
        switch self {
        case .textColor:
            return "Text Color"
        case .zoom:
            return "Zoom"
        case .none:
            return ""
        }
    }
}

extension SelectedButton: Hashable {
    
}
