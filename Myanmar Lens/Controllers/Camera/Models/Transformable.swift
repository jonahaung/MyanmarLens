//
//  Transformable.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 25/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

/// Objects that conform to the Transformable protocol are capable of being transformed with a `CGAffineTransform`.
protocol Transformable {
    func applying(_ transform: CGAffineTransform) -> Self

}

extension Transformable {

    func applyTransforms(_ transforms: [CGAffineTransform]) -> Self {
        
        var transformableObject = self
        
        transforms.forEach { (transform) in
            transformableObject = transformableObject.applying(transform)
        }
        
        return transformableObject
    }
    
}
