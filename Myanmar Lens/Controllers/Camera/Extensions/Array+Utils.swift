//
//  Array+Utils.swift
//  WeScan
//
//  Created by Boris Emorine on 2/8/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Vision
import Foundation

extension Array where Element == CGRect {
    
    /// Finds the biggest rectangle within an array of `Quadrilateral` objects.
    func biggest() -> CGRect? {
        let biggestRectangle = self.max(by: { (rect1, rect2) -> Bool in
            return rect1.width < rect2.width
        })
        
        return biggestRectangle
    }
    
}
