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

struct TextRect: Hashable {
    let text: String
    var rect: CGRect
    let id: String
    
    init(_ text: String, _ rect: CGRect) {
        self.text = text
        self.rect = rect
        self.id = text.withoutSpacesAndNewLines.include(in: .myanmarAlphabets)
    }
    
    func hash(into hasher: inout Hasher) {
        id.hashValue.hash(into: &hasher)
    }
}

enum BoxType {
    case Unstable, Stable, Busy, Unknown
    
    var stokeColor: UIColor {
        switch self {
        case .Unstable:
            return #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
        case .Stable:
            return #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        case .Busy:
            return #colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1)
        default:
            return #colorLiteral(red: 1, green: 0.5781051517, blue: 0, alpha: 1)
        }
    }
    
}

struct Box {
    
  
    var type: BoxType = .Unknown
    
    let cgrect: CGRect
    
    init(_ _rect: CGRect, trashold: CGFloat = 1) {
        cgrect = CGRect(x: _rect.minX.roundToNearest(trashold), y: _rect.minY.roundToNearest(trashold), width: _rect.size.width.roundToNearest(trashold), height: _rect.height.roundToNearest(trashold))
    }
    mutating func update(_ _type: BoxType) {
        type = _type
    }
}

extension Box: Hashable {
    func hash(into hasher: inout Hasher) {
        cgrect.height.hashValue.hash(into: &hasher)
        cgrect.width.hashValue.hash(into: &hasher)
        cgrect.origin.x.hashValue.hash(into: &hasher)
        cgrect.origin.y.hashValue.hash(into: &hasher)
    }
    func union(_ box: Box) -> Box {
        return Box(cgrect.union(box.cgrect))
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
