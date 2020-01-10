//
//  ImageRect.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 29/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit


struct TranslateTextRect {
    var translatedText: String?
    var textRect: TextRect
}

class TextRect {
    
    var text: String
    var translatedText: String?
    var rect: CGRect
    let id: String
    let isMyanmar: Bool
    var isStable = false
    
    var displayText: String { return translatedText ?? text }
    
    init(_ text: String, _ rect: CGRect, _isMyanmar: Bool) {
        self.text = text
        self.rect = rect
        isMyanmar = _isMyanmar
        if isMyanmar {
            id = text.trimmingCharacters(in: .whitespaces).include(in: .myanmarAlphabets)
        }else {
            id = text.trimmingCharacters(in: .removingCharacters).include(in: .englishAlphabets).withoutSpacesAndNewLines
        }
    }
}
// Hashable / Equable
extension TextRect: Hashable {
    func hash(into hasher: inout Hasher) {
        id.hashValue.hash(into: &hasher)
    }
    
    static func == (lhs: TextRect, rhs: TextRect) -> Bool {
        return lhs.id == rhs.id
    }
}
// Helpers
extension TextRect {
    
    func isSimilterText( _text: String) -> Bool {
        var newId: String
        if isMyanmar {
            newId = _text.include(in: .myanmarAlphabets)
        }else {
            newId = _text.withoutSpacesAndNewLines
        }
        return id == newId
    }

}
















enum BoxType {
    case Unstable, Stable, Busy, Unknown
    
    var stokeColor: UIColor {
        switch self {
        case .Unstable:
            return #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)
        case .Stable:
            return #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        case .Busy:
            return #colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1)
        default:
            return #colorLiteral(red: 1, green: 0.5781051517, blue: 0, alpha: 1)
        }
    }
    
}

struct Box {
    
    
    var type: BoxType = .Stable
    
    let cgrect: CGRect
    
    init(_ _rect: CGRect, trashold: CGFloat = 1) {
        cgrect = _rect
    }
    mutating func update(_ _type: BoxType) {
        type = _type
    }
}


extension CGRect {
    
    func trashole(trashold: CGFloat) ->CGRect {
        return CGRect(x: self.minX.roundToNearest(trashold), y: self.minY.roundToNearest(trashold), width: self.size.width.roundToNearest(trashold), height: self.height.roundToNearest(trashold))
    }
}
extension CGRect {
    var box: Box { return Box(self) }
}
