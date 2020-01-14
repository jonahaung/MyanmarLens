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
        clearlayers()
        let containerRect = overlayView.highlightLayerFrame
        for tr in textRects {
            let box = BoundingBox()
            box.addToLayer(overlayView.videoPreviewLayer)
            box.show(textRect: tr, within: containerRect)
            boxes.append(box)
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
