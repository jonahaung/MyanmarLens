//
//  BoxDrawer.swift
//  MathSolver
//
//  Created by Khoa Pham on 26.06.2018.
//  Copyright © 2018 onmyway133. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

final class BoxService {

    var overlayLayer: CameraOverlayLayer!
    private var color: UIColor = UIColor.systemIndigo

    func drawBoxes(rects: [CGRect], color: UIColor) {
        clearlayers()
        rects.forEach {
            let outline = CALayer()
            let frame = $0.inset(by: UIEdgeInsets(top: -3, left: -5, bottom: -3, right: -5))
            outline.frame = frame
            outline.cornerRadius = $0.height/2
            outline.backgroundColor = color.cgColor
            overlayLayer.addSublayer(outline)
        }
    }
    
    private func drawBox(overlayLayer: CAShapeLayer, normalisedRect: CGRect) {
    
        let outline = CALayer()
        let frame = overlayLayer.bounds.size.getNormalRect(for: normalisedRect).inset(by: UIEdgeInsets(top: -3, left: -8, bottom: -3, right: -8))
        outline.frame = frame
        outline.cornerRadius = 3
        outline.backgroundColor = color.cgColor
        overlayLayer.addSublayer(outline)
        
    }
    
    func clearlayers() {
        overlayLayer.sublayers?.forEach{ $0.removeFromSuperlayer() }
    }
}

extension CGSize {
    
    func getNormalRect(for normalisedRect: CGRect) -> CGRect {
        let x = normalisedRect.origin.x * width
        let y = normalisedRect.origin.y * height
        let w = normalisedRect.width * width
        let h = normalisedRect.height * height
        
        return CGRect(x: x, y: y, width: w, height: h)
    }
}

extension VNTextObservation {
    
    var normalized: CGRect {
        return CGRect(
            x: boundingBox.origin.x,
            y: 1 - boundingBox.origin.y - boundingBox.height,
            width: boundingBox.size.width,
            height: boundingBox.size.height
        )
    }
}
extension CGRect {
    func scaleUp(scaleUp: CGFloat) -> CGRect {
        let biggerRect = self.insetBy(
            dx: -self.size.width * scaleUp,
            dy: -self.size.height * scaleUp
        )
        
        return biggerRect
    }
    
    var normalized: CGRect {
        let boundingBox = self
        return CGRect(
            x: boundingBox.origin.x,
            y: 1 - boundingBox.origin.y - boundingBox.height,
            width: boundingBox.size.width,
            height: boundingBox.size.height
        )
    }
}
