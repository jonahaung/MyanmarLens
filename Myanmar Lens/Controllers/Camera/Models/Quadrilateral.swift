//
//  Quadrilateral.swift
//  WeScan
//
//  Created by Boris Emorine on 2/8/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import CoreGraphics

/// A data structure representing a quadrilateral and its position. This class exists to bypass the fact that CIRectangleFeature is read-only.

struct Quadrilateral: Transformable {
    
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomRight: CGPoint
    var bottomLeft: CGPoint
    
    var id: UUID?
    
    init(_ x: CIRectangleFeature) {
        topLeft = x.topLeft
        topRight = x.topRight
        bottomLeft = x.bottomLeft
        bottomRight = x.bottomRight
    }
    
    init(_ x: VNRectangleObservation) {
        topLeft = x.topLeft
        topRight = x.topRight
        bottomLeft = x.bottomLeft
        bottomRight = x.bottomRight
    }
    
    init(topLeft: CGPoint, topRight: CGPoint, bottomRight: CGPoint, bottomLeft: CGPoint) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
    }
    init(_ x: VNTextObservation) {
        topLeft = x.topLeft
        topRight = x.topRight
        bottomLeft = x.bottomLeft
        bottomRight = x.bottomRight
    }
    init(_ x: VNRecognizedTextObservation) {
        topLeft = x.topLeft
        topRight = x.topRight
        bottomLeft = x.bottomLeft
        bottomRight = x.bottomRight
        if let top = x.topCandidates(1).first {
            text = top.string
        }
    }
    init(_ x: VNDetectedObjectObservation) {
        let rect = x.boundingBox
        topLeft =  CGPoint(x: rect.minX, y: rect.maxY)
        topRight = CGPoint(x: rect.maxX, y: rect.maxY)
        bottomRight = CGPoint(x: rect.maxX, y: rect.minY)
        bottomLeft = CGPoint(x: rect.minX, y: rect.minY)
    }
    init(_ rect: CGRect) {
        topLeft =  CGPoint(x: rect.minX, y: rect.maxY)
        topRight = CGPoint(x: rect.maxX, y: rect.maxY)
        bottomRight = CGPoint(x: rect.maxX, y: rect.minY)
        bottomLeft = CGPoint(x: rect.minX, y: rect.minY)
        
    }
    init(_ rect: CGRect, id: UUID, textRects: [(String, CGRect)], text: String) {
        topLeft =  CGPoint(x: rect.minX, y: rect.maxY)
       topRight = CGPoint(x: rect.maxX, y: rect.maxY)
       bottomRight = CGPoint(x: rect.maxX, y: rect.minY)
       bottomLeft = CGPoint(x: rect.minX, y: rect.minY)
        self.id = id
        self.textRects = textRects
        self.text = text
    }
    
    var text: String = String()
    var textRects: [(String, CGRect)]?

    var description: String {
        return "topLeft: \(topLeft), topRight: \(topRight), bottomRight: \(bottomRight), bottomLeft: \(bottomLeft)"
    }
    
    /// The path of the Quadrilateral as a `UIBezierPath`
    var rectanglePath: UIBezierPath {
        let path = UIBezierPath()
        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addLine(to: bottomRight)
        path.addLine(to: bottomLeft)
        path.close()
        return path
    }

    var cornersPath: UIBezierPath {
        let rect = frame
        let thickness: CGFloat = 2
        let length: CGFloat = min(rect.height, rect.width) / 10
        let radius: CGFloat = 5
        let t2 = thickness / 2
        let path = UIBezierPath()
        
        let topSpace = self.topLeft.y
        let leftSpace = self.topLeft.x
        // Top left
        path.move(to: CGPoint(x: t2 + leftSpace, y: length + radius + t2 + topSpace))
        path.addLine(to: CGPoint(x: t2 + leftSpace, y: radius + t2 + topSpace))
        path.addArc(withCenter: CGPoint(x: radius + t2 + leftSpace, y: radius + t2 + topSpace), radius: radius, startAngle: CGFloat.pi, endAngle: CGFloat.pi * 3 / 2, clockwise: true)
        path.addLine(to: CGPoint(x: length + radius + t2 + leftSpace, y: t2 + topSpace))
        
        // Top right
        path.move(to: CGPoint(x: rect.width - t2 + leftSpace, y: length + radius + t2 + topSpace))
        path.addLine(to: CGPoint(x: rect.width - t2 + leftSpace, y: radius + t2 + topSpace))
        path.addArc(withCenter: CGPoint(x: rect.width - radius - t2 + leftSpace, y: radius + t2 + topSpace), radius: radius, startAngle: 0, endAngle: CGFloat.pi * 3 / 2, clockwise: false)
        path.addLine(to: CGPoint(x: rect.width - length - radius - t2 + leftSpace, y: t2 + topSpace))
        
        // Bottom left
        path.move(to: CGPoint(x: t2 + leftSpace, y: rect.height - length - radius - t2 + topSpace))
        path.addLine(to: CGPoint(x: t2 + leftSpace, y: rect.height - radius - t2 + topSpace))
        path.addArc(withCenter: CGPoint(x: radius + t2 + leftSpace, y: rect.height - radius - t2 + topSpace), radius: radius, startAngle: CGFloat.pi, endAngle: CGFloat.pi / 2, clockwise: false)
        path.addLine(to: CGPoint(x: length + radius + t2 + leftSpace, y: rect.height - t2 + topSpace))
        
        // Bottom right
        path.move(to: CGPoint(x: rect.width - t2 + leftSpace, y: rect.height - length - radius - t2 + topSpace))
        path.addLine(to: CGPoint(x: rect.width - t2 + leftSpace, y: rect.height - radius - t2 + topSpace))
        path.addArc(withCenter: CGPoint(x: rect.width - radius - t2 + leftSpace, y: rect.height - radius - t2 + topSpace), radius: radius, startAngle: 0, endAngle: CGFloat.pi / 2, clockwise: true)
        path.addLine(to: CGPoint(x: rect.width - length - radius - t2 + leftSpace, y: rect.height - t2 + topSpace))
      
        return path
    }
    
    var labelRect: CGRect {
    
        let rect = frame
        let size = CGSize(width: rect.width/3, height: UIFont.preferredFont(forTextStyle: .title2).pointSize)
        return CGRect(origin: CGPoint(x: rect.midX - size.width/2, y: rect.maxY), size: size)
    }
    /// The perimeter of the Quadrilateral
    var perimeter: Double {
        let perimeter = topLeft.distanceTo(point: topRight) + topRight.distanceTo(point: bottomRight) + bottomRight.distanceTo(point: bottomLeft) + bottomLeft.distanceTo(point: topLeft)
        return Double(perimeter)
    }
    
    /// Applies a `CGAffineTransform` to the quadrilateral.
    ///
    /// - Parameters:
    ///   - t: the transform to apply.
    /// - Returns: The transformed quadrilateral.
    func applying(_ transform: CGAffineTransform) -> Quadrilateral {
        let quadrilateral = Quadrilateral(topLeft: topLeft.applying(transform), topRight: topRight.applying(transform), bottomRight: bottomRight.applying(transform), bottomLeft: bottomLeft.applying(transform))
        
        return quadrilateral
    }
    
    /// Checks whether the quadrilateral is withing a given distance of another quadrilateral.
    ///
    /// - Parameters:
    ///   - distance: The distance (threshold) to use for the condition to be met.
    ///   - rectangleFeature: The other rectangle to compare this instance with.
    /// - Returns: True if the given rectangle is within the given distance of this rectangle instance.
    func isWithin(_ distance: CGFloat, ofRectangleFeature rectangleFeature: Quadrilateral) -> Bool {
        
        let topLeftRect = topLeft.surroundingSquare(withSize: distance)
        print(topLeftRect, rectangleFeature.topLeft)
        if !topLeftRect.contains(rectangleFeature.topLeft) {
            return false
        }
        
        let topRightRect = topRight.surroundingSquare(withSize: distance)
        if !topRightRect.contains(rectangleFeature.topRight) {
            return false
        }
        
        let bottomRightRect = bottomRight.surroundingSquare(withSize: distance)
        if !bottomRightRect.contains(rectangleFeature.bottomRight) {
            return false
        }
        
        let bottomLeftRect = bottomLeft.surroundingSquare(withSize: distance)
        if !bottomLeftRect.contains(rectangleFeature.bottomLeft) {
            return false
        }
        
        return true
    }
    
    /// Reorganizes the current quadrilateal, making sure that the points are at their appropriate positions. For example, it ensures that the top left point is actually the top and left point point of the quadrilateral.
    mutating func reorganize() {
        let points = [topLeft, topRight, bottomRight, bottomLeft]
        let ySortedPoints = sortPointsByYValue(points)
        
        guard ySortedPoints.count == 4 else {
            return
        }
        
        let topMostPoints = Array(ySortedPoints[0..<2])
        let bottomMostPoints = Array(ySortedPoints[2..<4])
        let xSortedTopMostPoints = sortPointsByXValue(topMostPoints)
        let xSortedBottomMostPoints = sortPointsByXValue(bottomMostPoints)
        
        guard xSortedTopMostPoints.count > 1,
            xSortedBottomMostPoints.count > 1 else {
                return
        }
        
        topLeft = xSortedTopMostPoints[0]
        topRight = xSortedTopMostPoints[1]
        bottomRight = xSortedBottomMostPoints[1]
        bottomLeft = xSortedBottomMostPoints[0]
    }
    
    /// Scales the quadrilateral based on the ratio of two given sizes, and optionaly applies a rotation.
    ///
    /// - Parameters:
    ///   - fromSize: The size the quadrilateral is currently related to.
    ///   - toSize: The size to scale the quadrilateral to.
    ///   - rotationAngle: The optional rotation to apply.
    /// - Returns: The newly scaled and potentially rotated quadrilateral.
    func scale(_ fromSize: CGSize, _ toSize: CGSize, withRotationAngle rotationAngle: CGFloat = 0.0) -> Quadrilateral {
        var invertedfromSize = fromSize
        let rotated = rotationAngle != 0.0
        
        if rotated && rotationAngle != CGFloat.pi {
            invertedfromSize = CGSize(width: fromSize.height, height: fromSize.width)
        }
        
        var transformedQuad = self
        let invertedFromSizeWidth = invertedfromSize.width == 0 ? .leastNormalMagnitude : invertedfromSize.width
        
        let scale = toSize.width / invertedFromSizeWidth
        let scaledTransform = CGAffineTransform(scaleX: scale, y: scale)
        transformedQuad = transformedQuad.applying(scaledTransform)
        
        if rotated {
            let rotationTransform = CGAffineTransform(rotationAngle: rotationAngle)
            
            let fromImageBounds = CGRect(origin: .zero, size: fromSize).applying(scaledTransform).applying(rotationTransform)
            
            let toImageBounds = CGRect(origin: .zero, size: toSize)
            let translationTransform = CGAffineTransform.translateTransform(fromCenterOfRect: fromImageBounds, toCenterOfRect: toImageBounds)
            
            transformedQuad = transformedQuad.applyTransforms([rotationTransform, translationTransform])
        }
        
        return transformedQuad
    }
    
    // Convenience functions
    
    /// Sorts the given `CGPoints` based on their y value.
    /// - Parameters:
    ///   - points: The poinmts to sort.
    /// - Returns: The points sorted based on their y value.
    private func sortPointsByYValue(_ points: [CGPoint]) -> [CGPoint] {
        return points.sorted { (point1, point2) -> Bool in
            point1.y < point2.y
        }
    }
    
    /// Sorts the given `CGPoints` based on their x value.
    /// - Parameters:
    ///   - points: The points to sort.
    /// - Returns: The points sorted based on their x value.
    private func sortPointsByXValue(_ points: [CGPoint]) -> [CGPoint] {
        return points.sorted { (point1, point2) -> Bool in
            point1.x < point2.x
        }
    }
}

extension Quadrilateral {
    
    /// Converts the current to the cartesian coordinate system (where 0 on the y axis is at the bottom).
    ///
    /// - Parameters:
    ///   - height: The height of the rect containing the quadrilateral.
    /// - Returns: The same quadrilateral in the cartesian corrdinate system.
    func toCartesian(withHeight height: CGFloat) -> Quadrilateral {
        let topLeft = self.topLeft.cartesian(withHeight: height)
        let topRight = self.topRight.cartesian(withHeight: height)
        let bottomRight = self.bottomRight.cartesian(withHeight: height)
        let bottomLeft = self.bottomLeft.cartesian(withHeight: height)
        
        return Quadrilateral(topLeft: topLeft, topRight: topRight, bottomRight: bottomRight, bottomLeft: bottomLeft)
    }
    
    var frame: CGRect {
        return CGRect(x: topLeft.x, y: topLeft.y, width: topRight.x - topLeft.x, height: bottomRight.y - topRight.y)
    }
}

extension Quadrilateral: Equatable {
    public static func == (lhs: Quadrilateral, rhs: Quadrilateral) -> Bool {
        return lhs.topLeft == rhs.topLeft && lhs.topRight == rhs.topRight && lhs.bottomRight == rhs.bottomRight && lhs.bottomLeft == rhs.bottomLeft
    }
}

