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
    
    init() {
        
        textLayer.shadowOpacity = 1
        textLayer.shadowOffset = .zero
        textLayer.shadowColor = UIColor.clear.cgColor
        textLayer.contentsScale = UIScreen.main.scale
//         textLayer.shadowRadius = 5
        textLayer.isHidden = true
       
    }
    
    func addToLayer(_ parent: CALayer) {
        parent.addSublayer(textLayer)
    }
    
    
    func show(textRect: TextRect, within region: CGRect) {
        textRect.region = region
        let backgroundColor = textRect.color?.cgColor ?? UIColor.white.cgColor
        textLayer.shadowColor = backgroundColor
        textLayer.backgroundColor = backgroundColor
        textLayer.foregroundColor = (textRect.color?.isLight() == true) ? UIColor.darkText.cgColor : UIColor.white.cgColor
        textLayer.fontSize = textRect.fontSize
        textLayer.font = textRect.font
        textLayer.frame = textRect.textLayerFrame()
        textLayer.string = textRect.text
        textLayer.isHidden = false
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        textLayer.setAffineTransform(textRect.transform())
        textLayer.frame.origin = textRect._rect.origin
        textLayer.shadowPath = CGPath(rect: textLayer.bounds.inset(by: UIEdgeInsets(top: -3, left: -3, bottom: -5, right: -8)), transform: nil)
        CATransaction.commit()
    }
    
    func hide() {
        
        textLayer.removeFromSuperlayer()
    }
}
