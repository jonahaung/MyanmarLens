//
//  VisionService.swift
//  MathSolver
//
//  Created by Khoa Pham on 26.06.2018.
//  Copyright © 2018 onmyway133. All rights reserved.
//

import Vision
import AVFoundation
import UIKit

protocol VisionServiceDelegate: class {
    func visionService(_ service: VisionService, drawBoxes rects: [CGRect])
    func visionService(_ service: VisionService, didGetImageRects imageRects: [ImageRect])
    func visionService(_ service: VisionService, didGetTextRects textRects: [TextRect])
}

final class VisionService {
    
    weak var delegate: VisionServiceDelegate?
    private var queue: RecognitionQueue<Int> = RecognitionQueue(desiredReliability: .tentative)
    private let context = CIContext.init(options: nil)
    private var requests = [VNRequest]()
    var isActive = false
    var parentBounds = CGRect.zero
    private(set) weak var cvImageBuffer: CVImageBuffer?
    var languagePair = LanguagePair(.burmese, .burmese) {
        didSet {
            let textRequest = requests.filter{ $0 is VNRecognizeTextRequest }
            if let x = textRequest.first as? VNRecognizeTextRequest {
                x.recognitionLanguages = [languagePair.0.rawValue]
            }
            isMyanmar = languagePair.0 == .burmese
        }
    }
    private var isMyanmar = true
    var regionOfInterest = CGRect.zero
    
    init() {
        
        let rectangelRequest = VNDetectTextRectanglesRequest(completionHandler: rectangleHandler(request:error:))
        rectangelRequest.reportCharacterBoxes = true
        rectangelRequest.usesCPUOnly = true
        rectangelRequest.preferBackgroundProcessing = true
        
        
        let textRequest = VNRecognizeTextRequest(completionHandler: textHandler(request:error:))
        textRequest.usesLanguageCorrection = true
        textRequest.usesCPUOnly = true
        textRequest.preferBackgroundProcessing = true
        textRequest.recognitionLevel = .fast
        requests = [rectangelRequest, textRequest]
    }
    
    
    func handle(sampleBuffer: CMSampleBuffer) {
        
        guard isActive, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        cvImageBuffer = pixelBuffer
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics: camData]
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: requestOptions)
        
        do {
            try handler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    private func rectangleHandler(request: VNRequest, error: Error?) {
        guard isActive, let rectangleResults = request.results as? [VNTextObservation] else { return }
        let confidents = rectangleResults.filter({ $0.confidence > 0.5 })
        
        let regionsRects = confidents.map{ getRect(box: $0, for: parentBounds)}.filter{regionOfInterest.contains($0)}
        delegate?.visionService(self, drawBoxes: regionsRects)
        
        guard isMyanmar else { return }
        

        let count = CGRect.sum(rects: regionsRects).area
        queue.enqueue(Int(count))
        guard queue.allValuesMatch, let stable = queue.dequeue(), stable > 0 else { return }
        isActive = false
        
        
        if let cvBuffer = self.cvImageBuffer {
            let ciImage = CIImage(cvImageBuffer: cvBuffer)
            
            guard
                let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
                else {
                    return
            }
            
            
            
            let uiImage = UIImage(cgImage: cgImage)
            let imageSize = uiImage.size
            
            var imageRects = [ImageRect]()
            
            for x in confidents {
                
                let labelRect = getRect(box: x, for: parentBounds)
                guard regionOfInterest.contains(labelRect) else { continue }
                let croppingRect = imageSize.getNormalRect(for: x.normalized)
                if let cropped = uiImage.cgImage?.cropping(to: croppingRect) {
                    let croppedImage = UIImage(
                        cgImage: cropped,
                        scale: uiImage.scale,
                        orientation: uiImage.imageOrientation)
                    imageRects.append(ImageRect(croppedImage, labelRect))
                }
            }
            delegate?.visionService(self, didGetImageRects: imageRects)
        }
        
    }
    
    private func textHandler(request: VNRequest, error: Error?) {
        guard isActive && !isMyanmar, let results = request.results as? [VNRecognizedTextObservation] else { return }
        let confidents = results.filter({ $0.confidence > 0.8 })
        
        var textRects = [TextRect]()
        for region in confidents {
            
            let rect = self.getRect(box: region)
            guard regionOfInterest.contains(rect), let top = region.topCandidates(1).first else { continue }
            let textRect = TextRect(top.string, rect)
            textRects.append(textRect)
        }
        let rects = textRects.map{ $0.1 }
        let count = CGRect.sum(rects: rects).area
        
        queue.enqueue(Int(count))
        guard queue.allValuesMatch, let stable = queue.dequeue(), stable > 0 else { return }
        isActive = false
        
        delegate?.visionService(self, didGetTextRects: textRects)
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
        return CGRect(x: xCoord, y: yCoord, width: width, height: height).integral
    }
    
    func getRect(box: VNRecognizedTextObservation) -> CGRect {
        
        let xCoord = box.topLeft.x * parentBounds.size.width
        let yCoord = (1 - box.topLeft.y) * parentBounds.size.height
        let width = (box.topRight.x - box.bottomLeft.x) * parentBounds.size.width
        let height = (box.topLeft.y - box.bottomLeft.y) * parentBounds.size.height
        return CGRect(x: xCoord, y: yCoord, width: width, height: height).integral
    }
    
    func reset() {
        cvImageBuffer = nil
        queue.clear()
    }
}
