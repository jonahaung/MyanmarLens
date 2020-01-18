//
//  CGRect+Utils.swift
//  WeScan
//
//  Created by Boris Emorine on 2/26/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import Vision
extension CGRect {
    
    /// Returns a new `CGRect` instance scaled up or down, with the same center as the original `CGRect` instance.
    /// - Parameters:
    ///   - ratio: The ratio to scale the `CGRect` instance by.
    /// - Returns: A new instance of `CGRect` scaled by the given ratio and centered with the original rect.
    func scaleAndCenter(withRatio ratio: CGFloat) -> CGRect {
        let scaleTransform = CGAffineTransform(scaleX: ratio, y: ratio)
        let scaledRect = applying(scaleTransform)
        
        let translateTransform = CGAffineTransform(translationX: origin.x * (1 - ratio) + (width - scaledRect.width) / 2.0, y: origin.y * (1 - ratio) + (height - scaledRect.height) / 2.0)
        let translatedRect = scaledRect.applying(translateTransform)
        
        return translatedRect
    }
    
}

extension CGRect {
    
    func viewRect(for size: CGSize) -> CGRect {
        return VNImageRectForNormalizedRect(self, size.width.int, size.height.int).integral
    }
    
    func vnRect(for parentSize: CGSize) -> CGRect {
        return  VNNormalizedRectForImageRect(self, parentSize.width.int, parentSize.height.int).integral
    }
    
    func normalized() ->CGRect {
        
        return CGRect(
            x: origin.x,
            y: 1 - origin.y - height,
            width: size.width,
            height: size.height
        )
    }
    
    static func createScaledFrame(featureFrame: CGRect, imageSize: CGSize, viewFrame: CGRect) -> CGRect {
        
        let viewSize = viewFrame.size
        // 2
        let resolutionView = viewSize.width / viewSize.height
        let resolutionImage = imageSize.width / imageSize.height
        
        // 3
        var scale: CGFloat
        if resolutionView > resolutionImage {
            scale = viewSize.height / imageSize.height
        } else {
            scale = viewSize.width / imageSize.width
        }
        
        // 4
        let featureWidthScaled = featureFrame.size.width * scale
        let featureHeightScaled = featureFrame.size.height * scale
        
        // 5
        let imageWidthScaled = imageSize.width * scale
        let imageHeightScaled = imageSize.height * scale
        let imagePointXScaled = (viewSize.width - imageWidthScaled) / 2
        let imagePointYScaled = (viewSize.height - imageHeightScaled) / 2
        
        // 6
        let featurePointXScaled = imagePointXScaled + featureFrame.origin.x * scale
        let featurePointYScaled = imagePointYScaled + featureFrame.origin.y * scale
        
        // 7
        return CGRect(x: featurePointXScaled,
                      y: featurePointYScaled,
                      width: featureWidthScaled,
                      height: featureHeightScaled)
    }
}
