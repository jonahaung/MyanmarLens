//
//  SaliencyDetector.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 15/3/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import Foundation
import Vision
import AVFoundation
import CoreImage

struct ObjectDetector {
    
    static func object(for pixelBuffer: CVPixelBuffer, completion: @escaping ((Quadrilateral?) -> Void)) {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        let request = VNGenerateObjectnessBasedSaliencyImageRequest { (x, err) in
            
            guard let results = (x.results?.first as? VNSaliencyImageObservation)?.salientObjects else {
                completion(nil)
                return
            }
            
            
            let quads: [Quadrilateral] = results.map(Quadrilateral.init)

            guard let biggest = quads.biggest() else {
                completion(nil)
                return
            }

            completion(biggest)
        }
        
        request.regionOfInterest = OcrService.roi
        do {
            try requestHandler.perform([request])
        }catch { print(error )}
    }
    
    static func attention(for pixelBuffer: CVPixelBuffer, completion: @escaping ((Quadrilateral?) -> Void)) {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        let request = VNGenerateAttentionBasedSaliencyImageRequest { (x, err) in
            guard let results = (x.results?.first as? VNSaliencyImageObservation)?.salientObjects else {
                completion(nil)
                return
            }

            if results.count == 0 {
                completion(nil)
                return
            }
            let quads: [Quadrilateral] = results.map(Quadrilateral.init)

            guard let biggest = quads.biggest() else {
                completion(nil)
                return
            }

            completion(biggest)
        }
        request.regionOfInterest = OcrService.roi
        do {
            try requestHandler.perform([request])
        }catch { print(error )}
    }
    
    static func detectTextRectangle(for pixelBuffer: CVPixelBuffer, completion: @escaping ((Int) -> Void)) {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        let request = VNDetectTextRectanglesRequest { (x, err) in
            guard let results = x.results as? [VNTextObservation] else {
                completion(0)
                return                
            }
            
            completion(results.count)
            
        }
        request.reportCharacterBoxes = false
        request.regionOfInterest = OcrService.roi.normalized()
        do {
            try requestHandler.perform([request])
        }catch { print(error )}
    }
    static func text(for pixelBuffer: CVPixelBuffer, completion: @escaping ((Quadrilateral?) -> Void)) {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        let request = VNRecognizeTextRequest { (x, err) in
            guard var results = x.results as? [VNRecognizedTextObservation], results.count > 0 else {
                completion(nil)
                return
            }
            results = results.filter{ OcrService.roi.contains($0.boundingBox)}
            
            let quads = results.map(Quadrilateral.init)
           
            let textRects = quads.map{($0.text, $0.frame)}.filter{ !$0.0.isEmpty }
           
            
            if textRects.count == 0 {
                completion(nil)
                return
            }
            
            let rect = textRects.map{ $0.1 }.reduce(CGRect.null, {$0.union($1)}).insetBy(dx: -0.02, dy: -0.02)
            var quad = Quadrilateral(rect)
            quad.quadrilaterals = quads
            quad.imageBuffer = pixelBuffer
            let texts = textRects.map{ $0.0 }.joined(separator: "\n").lowercased()
            quad.text = texts.language == "en" ? "English" : "Burmese"
            completion(quad)
            
        }
        request.usesLanguageCorrection = true
        request.recognitionLevel = .accurate
        do {
            try requestHandler.perform([request])
        }catch { print(error )}
    }
    static func rectangle(for pixelBuffer: CVPixelBuffer, intersect rect: CGRect, completion: @escaping ((Quadrilateral?) -> Void)) {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        let request = VNDetectRectanglesRequest(completionHandler: { (request, error) in
            guard let results = request.results as? [VNRectangleObservation], !results.isEmpty else {
                completion(nil)
                return
            }
            
           
            let quads: [Quadrilateral] = results.map(Quadrilateral.init)
            let interests = quads.filter{ $0.frame.intersects(rect)}
            guard let biggest = interests.biggest() else {
                completion(nil)
                return
            }
            
            completion(biggest)
        })
//        request.regionOfInterest = OcrService.roi
        request.minimumConfidence = 0.7
        request.maximumObservations = 15
        request.minimumAspectRatio = 0.3
        
        do {
            try requestHandler.perform([request])
        }catch { print(error )}
    }
    static func human(for pixelBuffer: CVPixelBuffer, completion: @escaping ((Quadrilateral?) -> Void)) {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
    
        let request = VNDetectHumanRectanglesRequest { (x, err) in
            guard let results = x.results as? [VNDetectedObjectObservation] else {
                completion(nil)
                return
            }
            
            let quads: [Quadrilateral] = results.map(Quadrilateral.init)
            
            guard let biggest = quads.biggest() else {
                completion(nil)
                return
            }
            
            completion(biggest)
            
        }

        do {
            try requestHandler.perform([request])
        }catch { print(error )}
    }
    
    static func horizon(for pixelBuffer: CVPixelBuffer, completion: @escaping ((CGAffineTransform?) -> Void)) {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        let request = VNDetectHorizonRequest { (x, err) in
            guard let results = x.results as? [VNHorizonObservation] else {
                completion(nil)
                return
            }
            
            completion(results.first?.transform)
            
        }

        do {
            try requestHandler.perform([request])
        }catch { print(error )}
    }
    static func animal(for pixelBuffer: CVPixelBuffer, completion: @escaping ((Quadrilateral?) -> Void)) {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        let request = VNRecognizeAnimalsRequest { (x, err) in
            guard var results = x.results as? [VNRecognizedObjectObservation] else {
                completion(nil)
                return
            }
            results = results.sorted{ $0.confidence > $1.confidence }
            guard let first = results.first else {
                completion(nil)
                return
            }
            var quad = Quadrilateral(first)
            quad.text = first.labels.first?.identifier ?? ""
            
            completion(quad)
            
        }

        do {
            try requestHandler.perform([request])
        }catch { print(error )}
    }
    
    
    private static func completeImageRequest(for request: VNImageRequestHandler, width: CGFloat, height: CGFloat, completion: @escaping ((Quadrilateral?) -> Void)) {
        // Create the rectangle request, and, if found, return the biggest rectangle (else return nothing).
        let rectangleDetectionRequest: VNDetectRectanglesRequest = {
            let rectDetectRequest = VNDetectRectanglesRequest(completionHandler: { (request, error) in
                guard error == nil, let results = request.results as? [VNRectangleObservation], !results.isEmpty else {
                    completion(nil)
                    return
                }

                let quads: [Quadrilateral] = results.map(Quadrilateral.init)

                guard let biggest = quads.biggest() else { // This can't fail because the earlier guard protected against an empty array, but we use guard because of SwiftLint
                    completion(nil)
                    return
                }

                let transform = CGAffineTransform.identity
                    .scaledBy(x: width, y: height)

                completion(biggest.applying(transform))
            })

            rectDetectRequest.minimumConfidence = 0.8
            rectDetectRequest.maximumObservations = 15
            rectDetectRequest.minimumAspectRatio = 0.3

            return rectDetectRequest
        }()

        // Send the requests to the request handler.
        do {
            try request.perform([rectangleDetectionRequest])
        } catch {
            completion(nil)
            return
        }

    }
    
    /// Detects rectangles from the given CVPixelBuffer/CVImageBuffer on iOS 11 and above.
    ///
    /// - Parameters:
    ///   - pixelBuffer: The pixelBuffer to detect rectangles on.
    ///   - completion: The biggest rectangle on the CVPixelBuffer
    static func rectangle(forPixelBuffer pixelBuffer: CVPixelBuffer, completion: @escaping ((Quadrilateral?) -> Void)) {
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        ObjectDetector.completeImageRequest(
            for: imageRequestHandler,
            width: CGFloat(CVPixelBufferGetWidth(pixelBuffer)),
            height: CGFloat(CVPixelBufferGetHeight(pixelBuffer)),
            completion: completion)
    }
    
    /// Detects rectangles from the given image on iOS 11 and above.
    ///
    /// - Parameters:
    ///   - image: The image to detect rectangles on.
    /// - Returns: The biggest rectangle detected on the image.
    static func rectangle(forImage image: CIImage, completion: @escaping ((Quadrilateral?) -> Void)) {
        let imageRequestHandler = VNImageRequestHandler(ciImage: image, options: [:])
        ObjectDetector.completeImageRequest(
            for: imageRequestHandler, width: image.extent.width,
            height: image.extent.height, completion: completion)
    }
    
    static func rectangle(forImage image: CIImage, orientation: CGImagePropertyOrientation, completion: @escaping ((Quadrilateral?) -> Void)) {
        let imageRequestHandler = VNImageRequestHandler(ciImage: image, orientation: orientation, options: [:])
        let orientedImage = image.oriented(orientation)
        ObjectDetector.completeImageRequest(
            for: imageRequestHandler, width: orientedImage.extent.width,
            height: orientedImage.extent.height, completion: completion)
    }
}


import CoreImage
/// Class used to detect rectangles from an image.
struct CIRectangleDetector {
    
    static let rectangleDetector = CIDetector(ofType: CIDetectorTypeRectangle,
                                              context: CIContext(options: nil),
                                              options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    
    /// Detects rectangles from the given image on iOS 10.
    ///
    /// - Parameters:
    ///   - image: The image to detect rectangles on.
    /// - Returns: The biggest detected rectangle on the image.
    static func rectangle(forImage image: CIImage, completion: @escaping ((Quadrilateral?) -> Void)) {
        let biggestRectangle = rectangle(forImage: image)
        completion(biggestRectangle)
    }
    
    static func rectangle(forImage image: CIImage) -> Quadrilateral? {
        guard let rectangleFeatures = rectangleDetector?.features(in: image) as? [CIRectangleFeature] else {
            return nil
        }
        
        let quads = rectangleFeatures.map { rectangle in
            return Quadrilateral(rectangle)
        }
        
        return quads.biggest()
    }
}