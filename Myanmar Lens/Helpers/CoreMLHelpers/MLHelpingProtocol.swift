//
//  MLHelpingProtocol.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 25/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit
import Vision
typealias TextPrediction = (labelIndex: Int, confidence: Float, boundingBox: CGRect)
struct Prediction {
    let classIndex: Int
    let score: Float
    let rect: CGRect
}
protocol MLHelpingProtocol {
    
}

extension MLHelpingProtocol {
    
    func IOU(_ a: CGRect, _ b: CGRect) -> Float {
        let areaA = a.width * a.height
        if areaA <= 0 { return 0 }
        
        let areaB = b.width * b.height
        if areaB <= 0 { return 0 }
        
        let intersectionMinX = max(a.minX, b.minX)
        let intersectionMinY = max(a.minY, b.minY)
        let intersectionMaxX = min(a.maxX, b.maxX)
        let intersectionMaxY = min(a.maxY, b.maxY)
        let intersectionArea = max(intersectionMaxY - intersectionMinY, 0) *
            max(intersectionMaxX - intersectionMinX, 0)
        return Float(intersectionArea / (areaA + areaB - intersectionArea))
    }
    
    func nonMaxSuppression(predictions: [TextPrediction], iouThreshold: Float, maxBoxes: Int) -> [Int] {
        return nonMaxSuppression(predictions: predictions, indices: Array(predictions.indices), iouThreshold: iouThreshold, maxBoxes: maxBoxes)
    }
    
    func nonMaxSuppression(predictions: [TextPrediction], indices: [Int], iouThreshold: Float, maxBoxes: Int) -> [Int] {
        
        // Sort the boxes based on their confidence scores, from high to low.
        let sortedIndices = indices.sorted { predictions[$0].confidence > predictions[$1].confidence }
        
        var selected: [Int] = []
        
        for i in 0..<sortedIndices.count {
            if selected.count >= maxBoxes { break }
            
            var shouldSelect = true
            let boxA = predictions[sortedIndices[i]]
            
            
            for j in 0..<selected.count {
                let boxB = predictions[selected[j]]
                if IOU(boxA.boundingBox, boxB.boundingBox) > iouThreshold {
                    shouldSelect = false
                    break
                }
            }
            
            if shouldSelect {
                selected.append(sortedIndices[i])
            }
        }
        
        return selected
    }
    
    func nonMaxSuppression(boxes: [Prediction], limit: Int, threshold: Float) -> [Prediction] {
        
        // Do an argsort on the confidence scores, from high to low.
        let sortedIndices = boxes.indices.sorted { boxes[$0].score > boxes[$1].score }
        
        var selected: [Prediction] = []
        var active = [Bool](repeating: true, count: boxes.count)
        var numActive = active.count
        
        outer: for i in 0..<boxes.count {
            if active[i] {
                let boxA = boxes[sortedIndices[i]]
                selected.append(boxA)
                if selected.count >= limit { break }
                
                for j in i+1..<boxes.count {
                    if active[j] {
                        let boxB = boxes[sortedIndices[j]]
                        if IOU(boxA.rect, boxB.rect) > threshold {
                            active[j] = false
                            numActive -= 1
                            if numActive <= 0 { break outer }
                        }
                    }
                }
            }
        }
        return selected
    }
    
    /**
     Multi-class version of non maximum suppression.
     
     Where `nonMaxSuppression()` does not look at the class of the predictions at
     all, the multi-class version first selects the best bounding boxes for each
     class, and then keeps the best ones of those.
     
     With this method you can usually expect to see at least one bounding box for
     each class (unless all the scores for a given class are really low).
     
     Based on code from: https://github.com/tensorflow/models/blob/master/object_detection/core/post_processing.py
     
     - Parameters:
     - numClasses: the number of classes
     - predictions: an array of bounding boxes and their scores
     - scoreThreshold: used to only keep bounding boxes with a high enough score
     - iouThreshold: used to decide whether boxes overlap too much
     - maxPerClass: the maximum number of boxes that will be selected per class
     - maxTotal: maximum number of boxes that will be selected over all classes
     
     - Returns: the array indices of the selected bounding boxes
     */
    //public func nonMaxSuppressionMultiClass(numClasses: Int,
    //                                        predictions: [NMSPrediction],
    //                                        scoreThreshold: Float,
    //                                        iouThreshold: Float,
    //                                        maxPerClass: Int,
    //                                        maxTotal: Int) -> [Int] {
    //    var selectedBoxes: [Int] = []
    //
    //    // Look at all the classes one-by-one.
    //    for c in 0..<numClasses {
    //        var filteredBoxes = [Int]()
    //
    //        // Look at every bounding box for this class.
    //        for p in 0..<predictions.count {
    //            let prediction = predictions[p]
    //            if prediction.classIndex == c {
    //
    //                // Only keep the box if its score is over the threshold.
    //                if prediction.score > scoreThreshold {
    //                    filteredBoxes.append(p)
    //                }
    //            }
    //        }
    //
    //        // Only keep the best bounding boxes for this class.
    //        let nmsBoxes = nonMaxSuppression(predictions: predictions,
    //                                         indices: filteredBoxes,
    //                                         iouThreshold: iouThreshold,
    //                                         maxBoxes: maxPerClass)
    //
    //        // Add the indices of the surviving boxes to the big list.
    //        selectedBoxes.append(contentsOf: nmsBoxes)
    //    }
    //
    //    // Sort all the surviving boxes by score and only keep the best ones.
    //    let sortedBoxes = selectedBoxes.sorted { predictions[$0].score > predictions[$1].score }
    //    return Array(sortedBoxes.prefix(maxTotal))
    //}
    
    func cropImages(cgImage: CGImage, uiImage: UIImage, rect: CGRect) -> UIImage? {
        let imageSize = uiImage.size
        let scale = uiImage.scale
        let orientiation = uiImage.imageOrientation
        if let cropped = cgImage.cropping(to: rect.viewRect(for: imageSize)) {
            return UIImage(cgImage: cropped, scale: scale, orientation: orientiation)
        }
        return nil
    }
    
    func getRect(box: VNTextObservation, for frame: CGRect) -> CGRect {
        guard let boxes = box.characterBoxes else {return .zero}
        var xMin: CGFloat = 9999.0
        var xMax: CGFloat = 0.0
        var yMin: CGFloat = 9999.0
        var yMax: CGFloat = 0.0
        
        for char in boxes {
            if char.bottomLeft.x < xMin {xMin = char.bottomLeft.x}
            if char.bottomRight.x > xMax {xMax = char.bottomRight.x}
            if char.bottomRight.y < yMin {yMin = char.bottomRight.y}
            if char.topRight.y > yMax {yMax = char.topRight.y}
        }
        
        let xCoord = xMin * frame.size.width
        let yCoord = (1 - yMax) * frame.size.height
        let width = (xMax - xMin) * frame.size.width
        let height = (yMax - yMin) * frame.size.height
        return CGRect(x: xCoord, y: yCoord, width: width, height: height)
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
    private func createScaledFrame(featureFrame: CGRect, imageSize: CGSize, viewFrame: CGRect) -> CGRect {
        
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
