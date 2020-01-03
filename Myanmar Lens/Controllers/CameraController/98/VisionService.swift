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
import GPUImage

protocol VisionServiceDelegate: class {
    func visionService(_ service: VisionService, drawBoxes rects: [CGRect])
    func visionService(_ service: VisionService, didGetImageRects imageRects: [ImageRect])
    func visionService(_ service: VisionService, didGetTextRects textRects: [TextRect])
}

final class VisionService: NSObject {
    
    weak var delegate: VisionServiceDelegate?
    private var queue: RecognitionQueue<Int> = RecognitionQueue(desiredReliability: .tentative)
    private let context = CIContext.init(options: nil)
    private var isMyanmar = true
    var regionOfInterest = CGRect.zero
    private var requests = [VNRequest]()
    var isActive = false
    var parentBounds = CGRect.zero
    private(set) weak var currentSampleBuffer: CMSampleBuffer?
    var languagePair = LanguagePair(.burmese, .burmese) { didSet { isMyanmar = languagePair.0 == .burmese } }
    
    
    let model = LanguageDetector_1()
    
    override init() {
        super.init()
        let rectangelRequest = VNDetectTextRectanglesRequest(completionHandler: rectangleHandler(request:error:))
        rectangelRequest.reportCharacterBoxes = true
        rectangelRequest.usesCPUOnly = true
        rectangelRequest.preferBackgroundProcessing = true
        
        
        let textRequest = VNRecognizeTextRequest(completionHandler: textHandler(request:error:))
        textRequest.usesLanguageCorrection = true
        textRequest.usesCPUOnly = true
        textRequest.preferBackgroundProcessing = true
        textRequest.recognitionLevel = .fast
        textRequest.revision = VNRecognizeTextRequestRevision1
        requests = [rectangelRequest, textRequest]
    }
    
    
    func handle(sampleBuffer: CMSampleBuffer) {
        
        guard isActive, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
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
    private let crop = Crop()
    
    private func rectangleHandler(request: VNRequest, error: Error?) {
        
        guard let results = request.results as? [VNTextObservation] else { return }
        
        var predictions: [NMSPrediction] = []
        
        for result in results {
            let rect = getRect(box: result, for: parentBounds)
            guard regionOfInterest.contains(rect) else { continue }
            let prediction = NMSPrediction(result, result.confidence, rect)
            predictions.append(prediction)
        }
        
        let filteredIndices = predictions.indices.filter { predictions[$0].rect.height > 13 && predictions[$0].rect.width > 15}
        let selected = nonMaxSuppression(predictions: predictions, indices: filteredIndices, iouThreshold: 5, maxBoxes: 20)
        
        var filtered = [NMSPrediction]()
        for i in 0..<selected.count {
            let index = selected[i]
            let prediction = predictions[index]
            filtered.append(prediction)
        }
        
        let regionsRects = filtered.map{ $0.rect }
        delegate?.visionService(self, drawBoxes: regionsRects)
        guard isMyanmar else { return }
        
        let count = CGRect.sum(rects: regionsRects).area
        queue.enqueue(Int(count))
        guard queue.allValuesMatch, let stable = queue.dequeue(), stable > 0 else { return }
        
        if let cvBuffer = self.currentSampleBuffer {
            if let image = imageFromSampleBuffer(sampleBuffer: cvBuffer)?.greysCaled {
                let uiImage = resizeImage(image: image, targetSize: parentBounds.size)
                var imageRects = [ImageRect]()
                let finals = filtered.filter{ $0.classIndex is VNTextObservation}.compactMap{ $0 }
                finals.forEach { (final) in
                    if let cropped = uiImage.cgImage?.cropping(to: final.rect.scaleUp(scaleUp: 0.01)) {
                        let croppedImage = UIImage(cgImage: cropped, scale: uiImage.scale, orientation: uiImage.imageOrientation)
                        imageRects.append(ImageRect(croppedImage, final.rect))
                    }
                }
                
                delegate?.visionService(self, didGetImageRects: imageRects)
            }
        }
    }
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
    private func textHandler(request: VNRequest, error: Error?) {
        guard !isMyanmar, let results = request.results as? [VNRecognizedTextObservation], results.count > 0 else { return }
        
        var predictions: [NMSPrediction] = []
        
        for result in results {
            let rect = getRect(box: result)
            let prediction = NMSPrediction(result, result.confidence, rect)
            predictions.append(prediction)
            
        }
        
        let filteredIndices = predictions.indices.filter { regionOfInterest.contains(predictions[$0].rect ) }
        let selected = nonMaxSuppression(predictions: predictions, indices: filteredIndices, iouThreshold: 5, maxBoxes: 20)
        
        var filtered = [NMSPrediction]()
        for i in 0..<selected.count {
            let index = selected[i]
            let prediction = predictions[index]
            filtered.append(prediction)
        }
        let count = CGRect.sum(rects: filtered.map{ $0.rect }).area
        queue.enqueue(Int(count))
        guard queue.allValuesMatch, let stable = queue.dequeue(), stable > 0 else { return }
        
        let finals = filtered.filter{ $0.classIndex is VNRecognizedTextObservation}.compactMap{ $0 }
        
        var textRects = [TextRect]()
        for final in finals {
            guard let x = final.classIndex as? VNRecognizedTextObservation, let top = x.topCandidates(1).first else { continue }
            let textRect = TextRect(text: top.string, rect: final.rect)
            textRects.append(textRect)
        }
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
        currentSampleBuffer = nil
        queue.clear()
    }
}

extension VisionService: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        currentSampleBuffer = sampleBuffer
        guard self.isActive else { return }
        handle(sampleBuffer: sampleBuffer)
        DispatchQueue.main.async { [unowned self] in
            guard let cv = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            if let x = try? self.model.prediction(input: LanguageDetector_1Input(image: cv)) {
                print(x.classLabel)
            }
        }
    }
    func getCurrentImage() {
        
    }
}


extension UIImage {
    
    var greysCaled: UIImage {
        let filter = SaturationAdjustment()
        filter.saturation = 0
        return self.filterWithOperation(filter)
    }
}
