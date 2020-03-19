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
        for tr in textRects {
            let box = BoundingBox()
            boxes.append(box)
            box.addToLayer(overlayView.displayLayer)
            box.show(textRect: tr)
            
        }
    }
    
    func clearlayers() {
        boxes.forEach{ $0.hide() }
        boxes.removeAll()
    }
}
