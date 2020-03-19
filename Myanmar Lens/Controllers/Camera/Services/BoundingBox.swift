//
//  BoundingBox.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 4/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

struct BoundingBox {
    
    let textLayer = CATextLayer()
    let shapeLayer: CAShapeLayer
    
    init() {
        shapeLayer = CAShapeLayer()
        shapeLayer.isHidden = true
        shapeLayer.shouldRasterize = true
        shapeLayer.rasterizationScale = UIScreen.main.scale
        shapeLayer.shadowOpacity = 1
        shapeLayer.shadowRadius = 5
        shapeLayer.shadowOffset =  CGSize.zero
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.alignmentMode = .justified
        textLayer.isWrapped = true
        textLayer.isHidden = true
       
    }
    
    func addToLayer(_ parent: CALayer) {
        parent.addSublayer(shapeLayer)
        parent.addSublayer(textLayer)
        
    }
    
    
    func show(textRect: TextRect) {
        let fitFrame = textRect.textLayerFrame()
        
        textLayer.fontSize = textRect.fontSize
        textLayer.font = textRect.font
        textLayer.frame = fitFrame
        
        
        let colors = textRect.colors
        let backgroundColor = colors?.background
        let textColor = userDefaults.textTheme == .BlackAndWhite ? (backgroundColor?.isLight() == true ? UIColor.darkText : UIColor.white) : colors?.primary
        
        textLayer.isHidden = false
        shapeLayer.isHidden = false
        CATransaction.setDisableActions(true)
        shapeLayer.fillColor = backgroundColor?.cgColor
        shapeLayer.shadowColor = backgroundColor?.cgColor
        textLayer.foregroundColor = textColor?.cgColor

        textLayer.setAffineTransform(textRect.transform())
        textLayer.frame.origin.x = textRect._rect.origin.x
        let path = CGPath(rect: textRect._rect, transform: nil)
        shapeLayer.path = path
        shapeLayer.shadowPath = path
        textLayer.string = textRect.text
    }
    
    func hide() {
        shapeLayer.removeFromSuperlayer()
        textLayer.removeFromSuperlayer()
    }
    
}
