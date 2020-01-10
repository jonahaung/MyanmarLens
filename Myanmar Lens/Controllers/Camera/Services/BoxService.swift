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
        let existings = boxes.filter{ $0.textRect != nil }
        let frame = self.overlayView.bounds
        var currentBoxes = [BoundingBox]()
        for tr in textRects {
            if let existing = (existings.filter{ $0.textRect!.displayText == tr.displayText }).first {
                existing.show(textRect: tr, within: frame)
                currentBoxes.append(existing)
            } else {
                let box = BoundingBox()
                box.addToLayer(overlayView.videoPreviewLayer)
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
