//
//  FocusRectangleView.swift
//  WeScan
//
//  Created by Julian Schiavo on 16/11/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

final class FocusRectangleView: UIView {
    convenience init(touchPoint: CGPoint) {
        let originalSize: CGFloat = 140
        let finalSize: CGFloat = 10
        self.init(frame: CGRect(x: touchPoint.x - (originalSize / 2), y: touchPoint.y - (originalSize / 2), width: originalSize, height: originalSize))
        
        layer.cornerRadius = bounds.height/2
        backgroundColor = UIColor.lightText
       
        UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveEaseOut, animations: {
            self.frame.origin.x += (originalSize - finalSize) / 2
            self.frame.origin.y += (originalSize - finalSize) / 2
            
            self.frame.size.width -= (originalSize - finalSize)
            self.frame.size.height -= (originalSize - finalSize)
            self.layer.cornerRadius = self.bounds.height/2
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }
    
}
