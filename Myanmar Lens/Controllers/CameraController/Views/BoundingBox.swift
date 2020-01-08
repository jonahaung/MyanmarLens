//
//  BoundingBox.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 4/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

class BoundingBox: Equatable {
    
    static func == (lhs: BoundingBox, rhs: BoundingBox) -> Bool {
        return lhs.textRect?.displayText == rhs.textRect?.displayText
    }
    
    let textLayer = CATextLayer()
    var textRect: TextRect?
    
    init() {
        textLayer.shadowOpacity = 0.4
        textLayer.shadowOffset = .zero
        textLayer.shadowColor = UIColor.black.cgColor
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.isHidden = true
        textLayer.contentsScale = 2
    }
    
    func addToLayer(_ parent: CALayer) {
        parent.addSublayer(textLayer)
    }
    
    
    func show(textRect: TextRect, within region: CGRect) {
        self.textRect = textRect
        let text = textRect.displayText
        let frame = textRect.rect
        let isMyanmar = textRect.isMyanmar
        
        var textSize = frame.height * 0.8
        var font = isMyanmar ? UIFont.myanmarFont : UIFont.engFont
        font = font.withSize(textSize)
        
        let attributes = [
            NSAttributedString.Key.font: font as Any
        ]
        
        let preferredSize = text.boundingRect(with: CGSize(width: .infinity, height: textSize), options: .usesFontLeading, attributes: attributes, context: nil).size
        
        //        calculated.origin = frame.origin
        
        //        if calculated.maxX > superBounds.maxX {
        //            calculated.origin.x = superBounds.maxX - calculated.width
        //            if calculated.origin.x < 0 {
        //                calculated.size.width = superBounds.width - 6
        //                calculated.size.height = 17
        //                textLayer.fontSize = 15
        //                textLayer.font = (textLayer.font as? UIFont)?.withSize(15)
        //            }
        //        }
        //        print(frame, preferredSize)
        var newFrame = frame
        //        newFrame.size = preferredSize
        
        while newFrame.size.height > preferredSize.height {
            newFrame.size.height -= 0.5
            textSize = min(30, newFrame.height*0.6)
        }
        newFrame.size.width = preferredSize.width
        while newFrame.maxX >= region.maxX {
            newFrame.origin.x -= 0.5
            if newFrame.origin.x <= region.origin.x {
                
            }
        }
        CATransaction.begin()
         CATransaction.setDisableActions(true)
        textLayer.fontSize = textSize
        textLayer.font = font.withSize(textSize)
        
        textLayer.frame = newFrame
        textLayer.string = text
        textLayer.isHidden = false
        
       
        textLayer.shadowPath = CGPath(roundedRect: textLayer.bounds.inset(by: UIEdgeInsets(top: 0, left: -5, bottom: 0, right: -5)), cornerWidth: 5, cornerHeight: 5, transform: nil)
        CATransaction.commit()
    }
    
    func updateFrame(frame: CGRect) {
        if !textLayer.frame.intersects(frame) {
            textLayer.position = frame.center
        }
        
    }
    func hide() {
        
        textLayer.removeFromSuperlayer()
    }
    func destroy() {
        textLayer.removeFromSuperlayer()
    }
    
    func calculateOptimalFontSize(textLength: CGFloat, boundingBox: CGRect) -> CGFloat{
        
        let area:CGFloat = boundingBox.width * boundingBox.height
        var size = sqrt(area / textLength)
        repeat {
            size -= 0.1
        }while boundingBox.height < size
        return size
    }
    
}
