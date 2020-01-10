//
//  VisionService.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 4/1/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//


import Foundation
import Vision
import AVKit
import SwiftyTesseract

protocol OcrServiceDelegate: class {
    func ocrService(_ service: OcrService, didGetStableTextRects textRects: [TextRect])
    func ocrService(_ service: OcrService, didUpdate box: Box)
}

final class OcrService: NSObject {
    
    weak var delegate: OcrServiceDelegate?
    
    let context = CIContext(options: nil)
    
    static var roi = CGRect(x: 0, y: 0.25, width: 1, height: 0.75)
    private var tessrect = SwiftyTesseract(language: .burmese)
    
    private let sentenceTracker: ObjectTracker<String> = ObjectTracker(reliability: .tentative)
    
    private let requestHandler = VNSequenceRequestHandler()
    weak var pixelBuffer: CVPixelBuffer?
  
    private let videoLayer: AVCaptureVideoPreviewLayer
    private var currentImage: CGImage?
    var semaphore = DispatchSemaphore(value: 1)
    
    var objects: Set<TextRect> = Set<TextRect>()
    var stableTexts: [String: String] = [:]
    private var lastObservation: VNRectangleObservation?
    
    init(_overlayView: OverlayView) {
        videoLayer = _overlayView.videoPreviewLayer
        tessrect.preserveInterwordSpaces = true
        super.init()
        
    }
    deinit {
        stop()
        print("OCR")
        
    }
    
    private lazy var rectangelRequest: VNDetectTextRectanglesRequest = {
        let x = VNDetectTextRectanglesRequest(completionHandler: textRectangleHandler(request:error:))
        x.reportCharacterBoxes = false
        return x
    }()
    
    private lazy var textRequest: VNRecognizeTextRequest = {
        let x = VNRecognizeTextRequest(completionHandler: textHandler(request:error:))
        x.usesLanguageCorrection = true
        x.recognitionLevel = .accurate
        return x
    }()
    
    private var currentBox = CGRect.zero.box
    var isMyanmar = false
    var transform = CGAffineTransform.identity

}

// Eng
extension OcrService {
    private func textHandler(request: VNRequest, error: Error?) {
        guard var results = request.results as? [VNRecognizedTextObservation], results.count > 0 else {
            return }
        results = results.filter{ rectangelRequest.regionOfInterest.normalized().contains($0.boundingBox )}
    
        var textRects = [TextRect]()
        for result in results {
            if let top = result.topCandidates(1).first {
                let text = top.string
                if text.isWhitespace { continue }
                self.sentenceTracker.logFrame(objects: [text])
                
                if let stable = self.sentenceTracker.getStableItem() {
                    self.sentenceTracker.reset(object: stable)
                    self.stableTexts[stable.trimmingCharacters(in: .whitespaces).include(in: .myanmarAlphabets)] = stable
                }
                let xMin = result.topLeft.x
                let xMax = result.topRight.x
                let yMin = result.topLeft.y
                let ymax = result.bottomLeft.y
                
                let frame = CGRect(x: xMin, y: ymax, width: abs(xMin - xMax), height: abs(yMin-ymax)).applying(transform).integral
                
                let newTextRect = TextRect(text, frame, _isMyanmar: false)
                
                if let existing = (self.objects.filter{ $0 == newTextRect }).first {
                    existing.rect.origin = frame.origin
                    textRects.append(existing)
                    self.sentenceTracker.reset(object: existing.text)
                    continue
                }else {
                    if let found = self.stableTexts[newTextRect.id] {
                        self.sentenceTracker.reset(object: found)
                        newTextRect.text = found
                    }
                    newTextRect.isStable = true
                    textRects.append(newTextRect)
                }

            }
        }
        
        let sumRect = textRects.map{$0.rect}.reduce(CGRect.null) { $0.union($1)}.inset(by: UIEdgeInsets(top: -7, left: -5, bottom: -7, right: -10))
        currentBox = Box(sumRect, trashold: 5)
        
        currentBox.update(.Unstable)
        delegate?.ocrService(self, didUpdate: currentBox)
        semaphore.wait()

        delegate?.ocrService(self, didGetStableTextRects: textRects)
        
    }
}

// Mya
extension OcrService {
    
    func nonMaxSuppression(rects: [CGRect], threshold: Float, limit: Int) -> [CGRect] {
        // Do an argsort on the confidence scores, from high to low.
        let sortedIndices = rects.indices.sorted { rects[$0].area > rects[$1].area }
        
        var selected: [CGRect] = []
        var active = [Bool](repeating: true, count: rects.count)
        var numActive = active.count
        
        outer: for i in 0..<rects.count {
            if active[i] {
                let boxA = rects[sortedIndices[i]]
                selected.append(boxA)
                if selected.count >= limit { break }
                
                for j in i+1..<rects.count {
                    if active[j] {
                        let boxB = rects[sortedIndices[j]]
                        if boxB.intersects(boxA) {
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
    
    private func textRectangleHandler(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNTextObservation], results.count > 0 else { return }
        var rects = [CGRect]()
        
        for result in results {
            let xMin = result.topLeft.x
            let xMax = result.topRight.x
            let yMin = result.topLeft.y
            let ymax = result.bottomLeft.y
            let rect = CGRect(x: xMin, y: ymax, width: abs(xMin - xMax), height: abs(yMin-ymax)).applying(transform).integral
            rects.append(rect)
        }
        
        let sumRect = rects.reduce(CGRect.null) { $0.union($1)}.inset(by: UIEdgeInsets(top: -7, left: -5, bottom: -7, right: -10)).intersection(OcrService.roi.applying(transform)).integral
        
        currentBox = Box(sumRect, trashold: 5)
        
        currentBox.update(.Unstable)
        delegate?.ocrService(self, didUpdate: currentBox)

        semaphore.wait()
        guard let cgImage = self.getCurrentCgImage(), let cropped = self.cropImage(cgImage: cgImage, rect: currentBox.cgrect.applying(self.transform.inverted()).normalized())  else {
            self.semaphore.signal()
            return
        }
        autoreleasepool {
            self.tessrect.performOCR(on: cropped) {[weak self] result in
                guard let self = self else { return }
                var lines: [String] = []
                if let sentence = result, sentence.isWhitespace == false {
                    lines = sentence.lines().map{ $0.cleanUpMyanmarTexts() }.filter{ $0.isWhitespace == false && $0.utf16.count > 3 }
                }
                self.sentenceTracker.logFrame(objects: lines)
                
                if let stable = self.sentenceTracker.getStableItem() {
                    self.sentenceTracker.reset(object: stable)
                    self.stableTexts[stable.trimmingCharacters(in: .whitespaces).include(in: .myanmarAlphabets)] = stable
                }
                let sorted = self.nonMaxSuppression(rects: rects, threshold: 0.1, limit: lines.count).sorted{ $0.origin.y < $1.origin.y }
                guard let first = sorted.first, let last = sorted.last else { return }
                let absoluteHeight = last.maxY - first.minY
                let avHeight = (absoluteHeight / sorted.count.cgFloat) * 0.8
                let spacing = avHeight * 0.2
                var textRects = [TextRect]()
                
                var y = first.origin.y
                for (i, text) in lines.enumerated() {
                    
                    if i > sorted.count - 1 {
                        break
                    }
                    var frame = sorted[i]
                    
                    frame.origin.y = y
                    var size = UIFont.myanmarFont.withSize(avHeight * 1.2).sizeOfString(string: text, constrainedToWidth: self.currentBox.cgrect.width)
                    size.height = avHeight
                    frame.size = size
                    frame.origin.x = max(self.currentBox.cgrect.origin.x, frame.origin.x)
                    if frame.maxX > self.currentBox.cgrect.maxX {
                        frame.origin.x = self.currentBox.cgrect.minX
                    }
                    
                    y += avHeight + spacing
                    
                    let newTextRect = TextRect(text, frame, _isMyanmar: true)
                    if let existing = (self.objects.filter{ $0 == newTextRect }).first {
                        existing.rect = frame
                        textRects.append(existing)
                        self.sentenceTracker.reset(object: existing.text)
                        continue
                    }else {
                        if let found = self.stableTexts[newTextRect.id] {
                            newTextRect.text = found
                            newTextRect.isStable = true
                            self.sentenceTracker.reset(object: found)
                        }
                        textRects.append(newTextRect)
                    }
                }
                self.delegate?.ocrService(self, didGetStableTextRects: textRects)
            }
            
        }
    }
}

// Video Input
extension OcrService: VideoServiceDelegate {
    func videoService(_ service: VideoService, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        self.pixelBuffer = pixelBuffer
        if let buffer = pixelBuffer {
            let request = isMyanmar ? rectangelRequest : textRequest
            do {
                try requestHandler.perform([request], on: buffer, orientation: .up)
            } catch {
                print(error)
            }
        }
    }
    
}

// Others
extension OcrService {
    
    func cropImage(cgImage: CGImage, rect: CGRect) -> UIImage? {
        if let cropped = cgImage.cropping(to: rect.viewRect(for: VideoService.videoSize)) {
            return UIImage(cgImage: cropped, scale: CGFloat(1), orientation: .up)
        }
        return nil
    }
    
    func getCurrentCgImage() -> CGImage? {
        guard let cm = pixelBuffer else { return nil }
        let ciImage = CIImage(cvImageBuffer: cm)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
    
    func updateTransform() {
        let videoRect = self.videoLayer.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1))
        let visible = videoRect.intersection(self.videoLayer.visibleRect)
        let scaleT = CGAffineTransform(scaleX: visible.width, y: -visible.height)
        let translateT = CGAffineTransform(translationX: visible.minX, y: visible.maxY)
        transform = scaleT.concatenating(translateT)
    }
    
    func updateCache(_ objects: [TextRect]) {
        objects.forEach{
            if $0.translatedText != nil {
                self.objects.insert($0)
            }
        }
    }
    func start(){
        rectangelRequest.regionOfInterest = OcrService.roi.normalized()
        updateTransform()
        semaphore.signal()
    }
    
    func stop() {
        currentBox = CGRect.zero.box
        objects.removeAll()
        textRequest.cancel()
        rectangelRequest.cancel()
    }
    
}
