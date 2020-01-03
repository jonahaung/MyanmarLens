//
//  BoxDrawer.swift
//  MathSolver
//
//  Created by Khoa Pham on 26.06.2018.
//  Copyright © 2018 onmyway133. All rights reserved.
//

import UIKit
import Vision


final class BoxService {
    
    var overlayLayer: CameraOverlayLayer!
   
    private var boxes = [BoundingBox]()
    
    func drawBoxes(rects: [CGRect], fillColor: UIColor = .clear) {
        clearlayers()
        for (i, frame) in rects.enumerated() {
            
            if let box = boxes[exist: i] {
                box.show(frame: frame, fillColor: fillColor)
                
            }else {
                let box = BoundingBox()
                box.addToLayer(overlayLayer)
                box.show(frame: frame, fillColor: fillColor)
                boxes.append(box)
            }
        }
    }
    
    func drawBoxes(textRects: [TextRect]) {
        clearlayers()
        for (i, textRect) in textRects.enumerated() {
            if let box = boxes[exist: i] {
                box.show(frame: textRect.rect, fillColor: UIColor.systemFill)
                
            }else {
                let box = BoundingBox()
                box.addToLayer(overlayLayer)
                box.show(frame: textRect.rect, fillColor: UIColor.systemFill)
                boxes.append(box)
            }
        }
    }
    
    func drawBoxes(translateTextRects: [TranslateTextRect]) {
        clearlayers()
        for (i, ttr) in translateTextRects.enumerated() {
            if let box = boxes[exist: i] {
                box.show(frame: ttr.textRect.rect, fillColor: UIColor.systemFill)
            }else {
                let box = BoundingBox()
                box.addToLayer(overlayLayer)
                box.show(frame: ttr.textRect.rect, fillColor: UIColor.systemFill)
                boxes.append(box)
            }
        }
    }
    
    func clearlayers() {
        boxes.forEach{ $0.hide() }
    }
}
