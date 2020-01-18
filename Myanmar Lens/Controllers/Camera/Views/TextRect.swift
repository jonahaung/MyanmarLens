//
//  ImageRect.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 29/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

final class TextRect {
    let id: String
    var _text: String
    var translatedText: String?
    var _rect: CGRect
    private let _isMyanmar: Bool
    private var hasTranslated: Bool { return translatedText != nil }
    var text: String { return translatedText ?? _text }
    var isMyanmar: Bool { return hasTranslated ? !_isMyanmar : _isMyanmar }
    var fontSize: CGFloat { return _rect.height * 0.8}
    var font: UIFont { return (isMyanmar ? UIFont.myanmarFont : UIFont.engFont).withSize(fontSize) }
    var colors: UIImageColors?
    
    var textSize: CGSize { return text.boundingRect(with: CGSize(width: .greatestFiniteMagnitude, height: 150.0), options: [], attributes: [.font: font], context: nil).size}
    
    func textLayerFrame() -> CGRect{
        var frame = _rect
        frame.size = textSize
        return frame
    }
    
    func transform() -> CGAffineTransform {
        let size = textSize
        let xScale = min(5, (_rect.width/size.width))
        let yScale = min(5, (_rect.height/size.height))
        return CGAffineTransform(scaleX: xScale, y: yScale)
    }
    
    init(_ _text: String, _ _rect: CGRect, _isMyanmar: Bool, _image: UIImage?) {
        self._text = _text
        self._rect = _rect
        self._isMyanmar = _isMyanmar
        self.colors = _image?.getColors(quality: .highest)
        self.id = _text.withoutSpacesAndNewLines.lowercased()
    }
}

extension TextRect: Hashable {
    static func == (lhs: TextRect, rhs: TextRect) -> Bool {
        return lhs.text == rhs.text
    }
    
    func hash(into hasher: inout Hasher) {
        id.hashValue.hash(into: &hasher)
    }
}
extension CGRect {
    
    func trashole(trashold: CGFloat) ->CGRect {
        return CGRect(x: self.minX.roundToNearest(trashold), y: self.minY.roundToNearest(trashold), width: self.size.width.roundToNearest(trashold), height: self.height.roundToNearest(trashold))
    }
}
