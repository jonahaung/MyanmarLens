//
//  BoxDrawer.swift
//  MathSolver
//
//  Created by Khoa Pham on 26.06.2018.
//  Copyright © 2018 onmyway133. All rights reserved.
//

import UIKit

final class BoxService {
    
    private let overlayView: OverlayView
    
    init(_overlayView: OverlayView) {
        overlayView = _overlayView
    }
    
    private var boxes = [BoundingBox]()
    
  
    func handle(_ textRects: [TextRect]) {
        let frame = overlayView.highlightLayer.frame
        let existings = boxes.filter{ $0.textRect != nil }
        
        var currentBoxes = [BoundingBox]()
        for tr in textRects {
            if let existing = (existings.filter{ $0.textRect!.text == tr.text }).first {
                existing.updateFrame(frame: tr.rect)
                currentBoxes.append(existing)
            } else {
                let box = BoundingBox()
                box.addToLayer(overlayView.highlightLayer)
                box.show(textRect: tr, within: frame)
                boxes.append(box)
                currentBoxes.append(box)
            }
        }
        
        for x in boxes {
            if !currentBoxes.contains(x) {
                if let index = boxes.firstIndex(of: x) {
                    boxes.remove(at: index)
                    x.hide()
                }
            }
        }
//        let frame = overlayView.highlightLayer.frame
//        for (i, texRect) in textRects.enumerated() {
//            if let box = boxes[exist: i] {
//                box.show(textRect: texRect, within: frame)
//            }else {
//                let box = BoundingBox()
//                box.addToLayer(overlayView.highlightLayer)
//                box.show(textRect: texRect, within: frame)
//                boxes.append(box)
//            }
//        }
//        overlayView.highlightLayer.strokeColor = UIColor.tertiarySystemFill.cgColor
        
    }
    
    func handle(_ ttrs: [TranslateTextRect]) {
        var textRects = [TextRect]()
        
        for ttr in ttrs {
             let originalText = ttr.textRect.text
            let text = ttr.translatedText ?? originalText
            textRects.append(TextRect(text, ttr.textRect.rect))
        }
        handle(textRects)
    }

    
    func clearlayers() {
        boxes.forEach{ $0.hide() }
        boxes.removeAll()
    }
}



extension Double {
    func roundToDecimal(_ fractionDigits: Int) -> Double {
        let multiplier = pow(10, Double(fractionDigits))
        return Darwin.round(self * multiplier) / multiplier
    }
}
