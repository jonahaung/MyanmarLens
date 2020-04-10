//
//  Layout+Extenstions.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 7/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

enum HorizontalAlignment {
    case left
    case center
    case right
}

enum VerticalAlignment {
    case top
    case center
    case bottom
}

extension CGRect {
    var center: CGPoint { return CGPoint(x: midX, y: midY) }
}

extension CGSize {
    
    init(_ round: CGFloat) {
        self.init(width: round, height: round)
    }
    
    func bma_rect(inContainer containerRect: CGRect, xAlignament: HorizontalAlignment, yAlignment: VerticalAlignment, dx: CGFloat = 0, dy: CGFloat = 0) -> CGRect {
        let originX, originY: CGFloat
        
        // Horizontal alignment
        switch xAlignament {
        case .left:
            originX = 0
        case .center:
            originX = containerRect.midX - self.width / 2.0
        case .right:
            originX = containerRect.maxX - self.width
        }
        
        // Vertical alignment
        switch yAlignment {
        case .top:
            originY = 0
        case .center:
            originY = containerRect.midY - self.height / 2.0
        case .bottom:
            originY = containerRect.maxY - self.height
        }
        
        return CGRect(origin: CGPoint(x: originX, y: originY).bma_offsetBy(dx: dx, dy: dy), size: self)
    }
    
    func rectCentered(at: CGPoint) -> CGRect{
        let dx = self.width/2
        let dy = self.height/2
        let origin = CGPoint(x: at.x - dx, y: at.y - dy )
        return CGRect(origin: origin, size: self)
    }
    
    func scaleBy(_ factor: CGFloat) -> CGSize{
        return CGSize(width: self.width*factor, height: self.height*factor)
    }
    
    var bounds: CGRect {
        return CGRect(origin: .zero, size: self)
    }
}
extension CGPoint {
    
    func bma_offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + dx, y: self.y + dy)
    }
}


extension CGPoint {
    
    /// Returns a rectangle of a given size surounding the point.
    ///
    /// - Parameters:
    ///   - size: The size of the rectangle that should surround the points.
    /// - Returns: A `CGRect` instance that surrounds this instance of `CGpoint`.
    func surroundingSquare(withSize size: CGFloat) -> CGRect {
        return CGRect(x: x - size / 2.0, y: y - size / 2.0, width: size, height: size)
    }
    
    /// Checks wether this point is within a given distance of another point.
    ///
    /// - Parameters:
    ///   - delta: The minimum distance to meet for this distance to return true.
    ///   - point: The second point to compare this instance with.
    /// - Returns: True if the given `CGPoint` is within the given distance of this instance of `CGPoint`.
    func isWithin(delta: CGFloat, ofPoint point: CGPoint) -> Bool {
        return (abs(x - point.x) <= delta) && (abs(y - point.y) <= delta)
    }
    
    /// Returns the same `CGPoint` in the cartesian coordinate system.
    ///
    /// - Parameters:
    ///   - height: The height of the bounds this points belong to, in the current coordinate system.
    /// - Returns: The same point in the cartesian coordinate system.
    func cartesian(withHeight height: CGFloat) -> CGPoint {
        return CGPoint(x: x, y: height - y)
    }
    
    /// Returns the distance between two points
    func distanceTo(point: CGPoint) -> CGFloat {
        return hypot((self.x - point.x), (self.y - point.y))
    }
    
    /// Returns the closest corner from the point
    func closestCornerFrom(quad: Quadrilateral) -> CornerPosition {
        var smallestDistance = distanceTo(point: quad.topLeft)
        var closestCorner = CornerPosition.topLeft
        
        if distanceTo(point: quad.topRight) < smallestDistance {
            smallestDistance = distanceTo(point: quad.topRight)
            closestCorner = .topRight
        }
        
        if distanceTo(point: quad.bottomRight) < smallestDistance {
            smallestDistance = distanceTo(point: quad.bottomRight)
            closestCorner = .bottomRight
        }
        
        if distanceTo(point: quad.bottomLeft) < smallestDistance {
            smallestDistance = distanceTo(point: quad.bottomLeft)
            closestCorner = .bottomLeft
        }
        
        return closestCorner
    }
    
}
