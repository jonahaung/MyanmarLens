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
import TesseractOCR

protocol VisionServiceDelegate: class {
    func visionService(_ service: VisionService, didUpdate box: Box)
    func visionService(_ service: VisionService, didGetTextRects textRects: [TextRect])
    func visionService(_ service: VisionService, didGetStableTextRects textRects: [TextRect])
    
}

final class VisionService: NSObject {
    
    private lazy var rectangelRequest: VNDetectTextRectanglesRequest = {
        let x = VNDetectTextRectanglesRequest(completionHandler: textRectangleHandler(request:error:))
        x.reportCharacterBoxes = true
        
        x.usesCPUOnly = true
        x.preferBackgroundProcessing = false
        return x
    }()

    private lazy var textRequest: VNRecognizeTextRequest = {
        let x = VNRecognizeTextRequest(completionHandler: textHandler(request:error:))
        x.usesLanguageCorrection = true
        x.usesCPUOnly = true
        x.preferBackgroundProcessing = false
        x.recognitionLevel = .fast
        return x
    }()
    
   
    weak var delegate: VisionServiceDelegate?
    private let context = CIContext(options: nil)
    var isMyanmar = true {
        didSet {
            let reliability: Accurcy = isMyanmar ? .verifiable : .solid
            boxTracker.updateReliability(reliability: reliability)
        }
    }
    var regionOfInterest = CGRect.zero {
        didSet {
            updateRegionOfInterest()
        }
    }
    private var isStopped = true
    var parentBounds = CGRect.zero
    private(set) weak var currentSampleBuffer: CMSampleBuffer?
    private let tessrect = SwiftyTesseract(language: .burmese)
    private var boxTracker: RecognitionQueue<Box> = RecognitionQueue(reliability: .diamond)
    private let sentenceTracker: ObjectTracker<String> = ObjectTracker(reliability: .verifiable)
    override init() {
        super.init()
        tessrect.preserveInterwordSpaces = false
        tessrect.minimumCharacterHeight = Int(12)
    }
}

// Text
extension VisionService {
    
    private func textHandler(request: VNRequest, error: Error?) {
        guard var results = request.results as? [VNRecognizedTextObservation], results.count > 0 else { return }
        results = results.filter{ $0.confidence > 0.5 }
        let videoSize = parentBounds.size
        let rects = results.map{VNImageRectForNormalizedRect($0.boundingBox.normalized(), videoSize.width.int, videoSize.height.int).integral}
        var box = rects.reduce(CGRect.null) { $0.union($1)}.box 
        box.update(.Unstable)
        
        delegate?.visionService(self, didUpdate: box)
        guard !isStopped else { return }
        
        boxTracker.enqueue(box)
        
        guard boxTracker.allValuesMatch, var stableBox = boxTracker.dequeue() else { return }
        stableBox.update(.Stable)
        delegate?.visionService(self, didUpdate: stableBox)
        
        var textRects = [TextRect]()
        
        results.forEach { result in
            if let top = result.topCandidates(1).first {
                
                let rect = VNImageRectForNormalizedRect(result.boundingBox.normalized(), videoSize.width.int, videoSize.height.int).integral
                let text = top.string
                textRects.append(TextRect(text, rect))
            }
        }
        stop()
        self.delegate?.visionService(self, didGetStableTextRects: textRects)
        
    }
    
    func getRect(box: VNRecognizedTextObservation) -> CGRect {

      
        let xCoord = box.topLeft.x * parentBounds.width
        let yCoord = (1 - box.topLeft.y) * parentBounds.height
        let width = (box.topRight.x - box.bottomLeft.x) * parentBounds.width
        let height = (box.topLeft.y - box.bottomLeft.y) * parentBounds.height
        return CGRect(x: xCoord, y: yCoord, width: width, height: height)
        
    }
}

// Rectangle
extension VisionService: MLHelpingProtocol {
    
    private func textRectangleHandler(request: VNRequest, error: Error?) {
        guard var results = request.results as? [VNTextObservation], results.count > 0 else { return }
        results = results.filter{ $0.confidence > 0.5 }
        let videoSize = parentBounds.size
        var rects = results.map{VNImageRectForNormalizedRect(self.normalise(box: $0), videoSize.width.int, videoSize.height.int).integral}
        rects = rects.filter{ $0.width > 30 && $0.height > 10 && $0.width > $0.height }
        
        let sumRect = rects.reduce(CGRect.null) { $0.union($1)}
        var box = sumRect.box
       

        boxTracker.enqueue(box)
        guard boxTracker.allValuesMatch, var stable = boxTracker.dequeue() else {
            box.update(.Unstable)
            delegate?.visionService(self, didUpdate: box)
            return
        }
        stable.update(.Stable)
        delegate?.visionService(self, didUpdate: stable)
         guard !isStopped else { return }
        
        guard let cgImage = getCurrentCgImage() else { return }
        self.stop()
        
        let uiImage = UIImage(cgImage: cgImage)

        if let image = cropImages(cgImage: cgImage, uiImage: uiImage, rect: VNNormalizedRectForImageRect(stable.cgrect, videoSize.width.int, videoSize.height.int))?.greysCaled {
            tessrect.performOCR(on: image) { [weak self] result in
                guard let self = self else { return }
                guard self.isStopped else { return }
                if let sentence = result, sentence.isWhitespace == false {
                     let lines = sentence.lines().map{ $0.cleanUpMyanmarTexts() }.filter{ !$0.isWhitespace && $0.utf16.count > 3}
                    
                     let totalFramesCount = CGFloat(rects.count)
                    let averageX = stable.cgrect.minX - 4
                    let averageHeight = min(25, stable.cgrect.height / totalFramesCount)
                    
    
                    var y = stable.cgrect.minY
                    
                    var textRects = [TextRect]()
                    lines.forEach { line in
                        y += averageHeight + 3
                        textRects.append(TextRect(line, CGRect(origin: CGPoint(x: averageX, y: y), size: CGSize(width: self.regionOfInterest.width, height: averageHeight))))
                    }
                    self.delegate?.visionService(self, didGetStableTextRects: textRects)
        
                }
            }
        }
    }
    
    private func normalise(box: VNTextObservation) -> CGRect {
       return CGRect(
         x: box.boundingBox.origin.x,
         y: 1 - box.boundingBox.origin.y - box.boundingBox.height,
         width: box.boundingBox.size.width,
         height: box.boundingBox.size.height
       )
     }
    
    private func getCurrentCgImage() -> CGImage? {
        guard let sample = self.currentSampleBuffer, let cm = CMSampleBufferGetImageBuffer(sample) else { return nil }
        let ciImage = CIImage(cvImageBuffer: cm)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
    
    
}


// Buffer
extension VisionService: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func handle(sampleBuffer: CMSampleBuffer) {
        currentSampleBuffer = sampleBuffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        if isMyanmar {
            do {
                try handler.perform([rectangelRequest])

            }catch { print(error.localizedDescription )}
        } else {
         
            do {
                try handler.perform([textRequest])
            }catch { print(error.localizedDescription )}
        }
        
    }
    
    func handle(cgImage: CGImage) {

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        if isMyanmar {
            do {
                try handler.perform([rectangelRequest])

            }catch { print(error.localizedDescription )}
        } else {
         
            do {
                try handler.perform([textRequest])
            }catch { print(error.localizedDescription )}
        }
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        
        handle(sampleBuffer: sampleBuffer)
    }
    
    func start(){
        isStopped = false
        reset()
    }
    
    private func updateRegionOfInterest() {
        print(parentBounds)
        let roi = VNNormalizedRectForImageRect(regionOfInterest, parentBounds.width.int, parentBounds.height.int)
        textRequest.regionOfInterest = roi
        rectangelRequest.regionOfInterest = roi
    }
    func stop() {
        isStopped = true
        reset()
    }
    
    func reset() {
        textRequest.cancel()
        rectangelRequest.cancel()
        textRequest.cancel()
        boxTracker.dequeue()
        currentSampleBuffer = nil
        
        print("restart")
    }
}




