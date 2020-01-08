//
//  BBox.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 7/1/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import Foundation
import UIKit

class BBox: Equatable {
    
    static func == (lhs: BBox, rhs: BBox) -> Bool {
        return lhs.textRect == rhs.textRect
    }
    
    let shapeLayer: CAShapeLayer
    let textLayer: CATextLayer
    
    init() {
        shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 1
        shapeLayer.isHidden = true
        
        textLayer = CATextLayer()
        textLayer.isHidden = true
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.fontSize = 14
        textLayer.font = UIFont.myanmarFont
        textLayer.alignmentMode = CATextLayerAlignmentMode.center
    }
    
    func addToLayer(_ parent: CALayer) {
        parent.addSublayer(shapeLayer)
        parent.addSublayer(textLayer)
    }
    var textRect: TextRect?
    func show(textRect: TextRect) {
        self.textRect = textRect
        let frame = textRect.rect
        self.show(frame: frame, label: textRect.text, color: UIColor.separator, textColor: .white)
    }
    
    func updateFrame(frame: CGRect) {
        self.textLayer.position = frame.center
    }
    
    func show(frame: CGRect, label: String, color: UIColor, textColor: UIColor) {
        CATransaction.setDisableActions(true)
        
        let path = UIBezierPath(rect: frame)
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.isHidden = false
        textLayer.fontSize = (frame.height * 0.9).rounded()
        textLayer.string = label
        textLayer.foregroundColor = textColor.cgColor
        textLayer.backgroundColor = color.cgColor
        textLayer.isHidden = false
        textLayer.frame = frame
//        let attributes = [
//            NSAttributedString.Key.font: textLayer.font as Any
//        ]
//
//        let textRect = label.boundingRect(with: CGSize(width: 400, height: 100),
//                                          options: .truncatesLastVisibleLine,
//                                          attributes: attributes, context: nil)
//        let textSize = CGSize(width: textRect.width + 12, height: textRect.height)
//        let textOrigin = CGPoint(x: frame.origin.x - 2, y: frame.origin.y - textSize.height)
//        textLayer.frame = CGRect(origin: textOrigin, size: textSize)
    }
    
    func hide() {
        shapeLayer.isHidden = true
        textLayer.isHidden = true
        shapeLayer.removeFromSuperlayer()
        textLayer.removeFromSuperlayer()
    }
}
