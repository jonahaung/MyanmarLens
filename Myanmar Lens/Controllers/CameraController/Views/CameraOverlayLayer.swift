//
//  CameraOverlayLayer.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 29/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

final class CameraOverlayLayer: CAShapeLayer {
    
    override init() {
        super.init()
        fillRule = .evenOdd
        fillColor = UIColor.black.cgColor
        opacity = 0.7
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var regionOfInterest = CGRect.zero {
        didSet {
            drawRegion()
        }
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        drawRegion()
    }
    
    private func drawRegion() {
        let basePath = UIBezierPath(rect: bounds)
        let cutOutPath = UIBezierPath(roundedRect: regionOfInterest, cornerRadius: 10)
        basePath.append(cutOutPath)
        basePath.usesEvenOddFillRule = true
        path = basePath.cgPath
    }
}
