//
//  OcrService.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 29/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//
import Foundation
import Vision
import AVKit
import SwiftyTesseract

protocol OcrServiceDelegate: class {
    func ocrService(_ service: OcrService, didGetTextRects textRects: [TextRect])
    func ocrService(_ service: OcrService, didGetStableTextRects textRects: [TextRect])
    func ocrService(_ service: OcrService, didUpdate box: Box)
    func ocrService(_ service: OcrService, didUpdate progress: CGFloat)
}

final class OcrService: NSObject {
    
    weak var delegate: OcrServiceDelegate?
    
    private let context = CIContext(options: nil)
    var isMyanmar = false {
        didSet {
            boxTracker.updateReliability(reliability: isMyanmar ? .stable : .verifiable)
            if !isMyanmar {
                Async.main {
                    self.overlayView.highlightLayer.frame = self.overlayView.bounds
                }
            }
        }
    }
    
    
    
    private var queue = DispatchQueue(label: "OcrService.queue", attributes: .concurrent)
    
    static var roi = CGRect(x: 0, y: 0.4, width: 1, height: 0.6)
    private var tessrect = SwiftyTesseract(language: .burmese)
    private var boxTracker: RecognitionQueue<Box> = RecognitionQueue(reliability: .stable)
    private let sentenceTracker: ObjectTracker<String> = ObjectTracker(reliability: .raw)
    private let overlayView: OverlayView
    private let requestHandler = VNSequenceRequestHandler()
  weak var pixelBuffer: CVPixelBuffer?
    var isBusy = false
    private let videoLayer: AVCaptureVideoPreviewLayer
    private var texts = [String: Int]()
    private var isSatisfied = false
    private var semaphore = DispatchSemaphore(value: 1)
    private var engTexts: Set<String> = Set<String>()
    init(_overlayView: OverlayView) {
        overlayView = _overlayView
        videoLayer = _overlayView.videoPreviewLayer
        super.init()
        
    }
    deinit {
        semaphore.signal()
        stop()
        print("OCR")
        
    }
    
    private lazy var rectangelRequest: VNDetectTextRectanglesRequest = {
        let x = VNDetectTextRectanglesRequest(completionHandler: textRectangleHandler(request:error:))
        x.reportCharacterBoxes = true
        x.usesCPUOnly = true
        x.revision = VNDetectTextRectanglesRequestRevision1
        x.preferBackgroundProcessing = true
        return x
    }()
    
    private lazy var textRequest: VNRecognizeTextRequest = {
        let x = VNRecognizeTextRequest(completionHandler: textHandler(request:error:))
        x.usesLanguageCorrection = true
        x.usesCPUOnly = true
        x.preferBackgroundProcessing = true
        x.recognitionLevel = .fast
        return x
    }()
    
    private var currentBox = CGRect.zero.box
    
    
    private func textHandler(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNRecognizedTextObservation], results.count > 0 else { return }
        let boundingBoxes = results.map{ $0.boundingBox.trashole(trashold: 0.005).scaleUp(scaleUp: 0.02)}
        let rects = boundingBoxes.map{ $0.applying(transform)}
        
//        let sumRect = rects.reduce(CGRect.null) { $0.union($1)}.scaleUp(scaleUp: 0.02)
//        if sumRect.area > currentBox.cgrect.area {
//            var box = Box(sumRect, trashold: 5)
//            currentBox = box
//            box.update(isBusy ? .Busy : .Unstable)
//            delegate?.ocrService(self, didUpdate: box)
//            boxTracker.clear()
//        }
//
//
//        guard isBusy == false else { return }
//
//        boxTracker.enqueue(currentBox)
//        guard boxTracker.allValuesMatch, var stable = boxTracker.dequeue() else { return }
//        boxTracker.clear()
//
//        queue.async {
//            self.isBusy = true
//        }
//        stable.update(.Stable)
//        delegate?.ocrService(self, didUpdate: stable)
//        var textRects = [TextRect]()
//
//        guard self.isBusy else { return }
//        let absoluteHeight = rects.reduce(0, {$0 + $1.height })
//        let avHeight = (absoluteHeight / rects.count.cgFloat).rounded()
//        let spacing = CGFloat(3)
//
//        var y = CGFloat.zero
        var textRects = [TextRect]()
        for tur in zip(results, rects) {
            if let top = tur.0.topCandidates(1).first {
                let string = top.string
                textRects.append(TextRect(string, tur.1))
                
            }
            
        }
//        for result in results {
//            if let top = result.topCandidates(1).first, !top.string.isWhitespace {
////                let text = top.string
////                y += avHeight + spacing
////                var origin = CGPoint.zero
////                origin.y = y
////                var size = UIFont.myanmarFont.withSize(avHeight*0.8).sizeOfString(string: text, constrainedToWidth: stable.cgrect.width)
////                size.height = avHeight
//                let frame = result.boundingBox.applying(self.transform)
//                textRects.append(TextRect(top.string, frame))
//            }
//        }
//
        guard textRects.count > 0 else { return }
        self.delegate?.ocrService(self, didGetStableTextRects: textRects)
        
//        queue.async {
//            self.isBusy = false
//        }
    }
    
    
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
    
    var transform = CGAffineTransform.identity
}

extension OcrService: MLHelpingProtocol {
    
    func updateTransform() {
        let outputRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let videoRect = videoLayer.layerRectConverted(fromMetadataOutputRect: outputRect)
        let visible = videoRect.intersection(videoLayer.visibleRect)
        let scaleT = CGAffineTransform(scaleX: visible.width, y: -visible.height)
        let translateT = CGAffineTransform(translationX: 0, y: visible.height)
        transform = scaleT.concatenating(translateT)
    }
    private func textRectangleHandler(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNTextObservation], results.count > 0 else { return }
        let boundingBoxes = results.map{ $0.boundingBox.scaleUp(scaleUp: 0.03)}
        let rects = boundingBoxes.map{ $0.applying(transform).integral}
        
        let sumRect = rects.reduce(CGRect.null) { $0.union($1)}.inset(by: UIEdgeInsets(top: -7, left: -5, bottom: -7, right: -10))
        if sumRect.area > currentBox.cgrect.area {
            var box = Box(sumRect, trashold: 5)
            currentBox = box
            box.update(isBusy ? .Busy : .Unstable)
            delegate?.ocrService(self, didUpdate: box)
            boxTracker.clear()
        }
        
        
        guard isBusy == false else { return }
        
        boxTracker.enqueue(currentBox)
        guard boxTracker.allValuesMatch, var stable = boxTracker.dequeue() else { return }
        
        
        queue.async {
            self.isBusy = true
        }
        
        guard let cgImage = self.getCurrentCgImage(), let cropped = self.cropImage(cgImage: cgImage, rect: stable.cgrect.applying(transform.inverted()).normalized())?.greysCaled  else {
            isBusy = false
            return
        }
        
        stable.update(.Stable)
        delegate?.ocrService(self, didUpdate: stable)
        autoreleasepool {
            tessrect.performOCR(on: cropped) {[weak self] result in
                guard let self = self else { return }
                var lines: [String] = []
                if let sentence = result, sentence.isWhitespace == false {
                    lines = sentence.lines().map{ $0.cleanUpMyanmarTexts() }.filter{ $0.isWhitespace == false && $0.utf16.count > 3 }
                }
                guard self.isBusy else { return }
                let absoluteHeight = rects.reduce(0, {$0 + $1.height })
                let avHeight = (absoluteHeight / rects.count.cgFloat).rounded()
                let spacing = CGFloat(5)
                var textRects = [TextRect]()
                
                var y = CGFloat.zero - avHeight+spacing
                for text in lines {
                    y += avHeight + spacing
                    var origin = CGPoint.zero
                    
                    origin.y = y
                    var size = UIFont.myanmarFont.withSize(avHeight*0.8).sizeOfString(string: text, constrainedToWidth: stable.cgrect.width)
                    origin.x = (stable.cgrect.width - size.width) / 2
                    size.height = avHeight
                    let frame = CGRect(origin: origin, size: size).integral
                    textRects.append(TextRect(text, frame))
                }
                self.delegate?.ocrService(self, didGetStableTextRects: textRects)
                
                
            }
            
        }
        
    }
    
    private func getStableText() -> [String]? {
        if let x = self.sentenceTracker.getStableItem() {
            x.forEach{ self.sentenceTracker.reset(object: $0)}
            return x
        }
        return nil
    }
    
    func performOCR(image: UIImage, rects: [CGRect], _ completion: @escaping ([String]) -> Void) {
        
        
    }
    
    private func resume() {
        self.queue.async {[weak self] in
            guard let self = self else { return }
            self.isSatisfied = true
            self.isBusy = false
        }
    }
    
    func handle(pixelBuffer: CVPixelBuffer) {
        
        self.pixelBuffer = pixelBuffer
        let request = isMyanmar ? rectangelRequest : textRequest
        do {
            try requestHandler.perform([request], on: pixelBuffer, orientation: .up)
            
        }catch { print(error.localizedDescription )}
    }
}

extension OcrService {
    
    func start(){
        texts.removeAll()
        rectangelRequest.regionOfInterest = OcrService.roi.normalized()
//        textRequest.regionOfInterest = OcrService.roi.normalized()
        updateTransform()
        self.reset()
        queue.async {
            self.isBusy = false
            
        }
    }
    
    func stop() {
        
        isSatisfied = true
        textRequest.cancel()
        rectangelRequest.cancel()
        self.isBusy = true
    }
    
    func reset() {
        isSatisfied = false
        currentBox = CGRect.zero.box
        
        textRequest.cancel()
        rectangelRequest.cancel()
        boxTracker.clear()
        semaphore.signal()
        print("restart")
    }
}

extension UIFont {
    func sizeOfString (string: String, constrainedToWidth width: CGFloat) -> CGSize {
        let attributes = [NSAttributedString.Key.font: self.fontName,]
        let attString = NSAttributedString(string: string,attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attString)
        return CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(location: 0,length: 0), nil, CGSize(width: width, height: .greatestFiniteMagnitude), nil)
    }
}
/*
 
 return
 while !self.isSatisfied {
 let _ = semaphore.wait(timeout: .distantFuture)
 self.performOCR(image: cropped, rects: rects) {[weak self] lines in
 guard let self = self else { return }
 guard self.isBusy else { return }
 self.sentenceTracker.logFrame(objects: lines)
 if let stableTexts = self.getStableText() {
 stableTexts.forEach { stableText in
 if let index = lines.firstIndex(of: stableText) {
 self.texts[stableText] = index
 }
 let linesCount = lines.count
 
 if self.texts.count >= linesCount {
 self.isSatisfied = true
 let sorted = self.texts.sorted{ $0.value < $1.value }.map{ $0.key }
 let absoluteHeight = rects.reduce(0, {$0 + $1.height })
 let avHeight = (absoluteHeight / rects.count.cgFloat).rounded()
 let spacing = CGFloat(3)
 var textRects = [TextRect]()
 
 var y = CGFloat.zero
 for text in sorted {
 y += avHeight + spacing
 var origin = CGPoint.zero
 origin.y = y
 var size = UIFont.myanmarFont.withSize(avHeight*0.8).sizeOfString(string: text, constrainedToWidth: stable.cgrect.width)
 size.height = avHeight
 let frame = CGRect(origin: origin, size: size).integral
 textRects.append(TextRect(text, frame))
 }
 self.delegate?.ocrService(self, didGetStableTextRects: textRects)
 self.delegate?.ocrService(self, didUpdate: 0)
 }else {
 self.delegate?.ocrService(self, didUpdate: self.texts.count.cgFloat/linesCount.cgFloat)
 }
 }
 }
 
 
 
 self.semaphore.signal()
 }
 }
 private func textRectangleHandler(request: VNRequest, error: Error?) {
 guard !isBusy, let results = request.results as? [VNTextObservation], results.count > 0 else { return }
 let rects = results.map{ $0.boundingBox.trashole(trashold: 0.01)}
 
 let sumRect = OcrService.roi.intersection(rects.reduce(CGRect.null) { $0.union($1)}.scaleUp(scaleUp: 0.03))
 
 var box = Box(sumRect, trashold: 0.01)
 box.update(.Unstable)
 delegate?.ocrService(self, didUpdate: box)
 
 
 boxTracker.enqueue(box)
 guard boxTracker.allValuesMatch, var stable = boxTracker.dequeue() else { return }
 
 boxTracker.clear()
 self.isBusy = true
 
 stable.update(.Stable)
 delegate?.ocrService(self, didUpdate: stable)
 
 guard let cgImage = self.getCurrentCgImage(), let cropped = self.cropImage(cgImage: cgImage, rect: stable.cgrect.normalized())?.greysCaled  else {
 isBusy = false
 return
 }
 
 //        while !self.isSatisfied {
 //            self.performOCR(image: cropped, rects: rects)
 //            if self.isSatisfied {
 //                self.queue.async {
 //                    self.delegate?.ocrService(self, didGetStableTextRects: self.textRects.array)
 //                }
 //            }
 //        }
 //        return
 queue.async {
 self.isBusy = true
 
 self.tessrect.performOCR(on: cropped) { [weak self] result in
 guard let self = self else { return }
 
 if let sentence = result, sentence.isWhitespace == false {
 let lines = sentence.lines().map{ $0.cleanUpMyanmarTexts() }.filter{ $0.isWhitespace == false && $0.utf16.count > 3 }
 self.sentenceTracker.logFrame(objects: lines)
 
 self.isBusy = false
 let sortedRects = rects.sorted{ $0.width > $1.width }
 let sortedTexts = lines.sorted{ $0.count > $1.count }
 let textCount = sortedTexts.count
 
 var unorderedTextRects = [String: CGSize]()
 for turple in sortedRects.enumerated() {
 let i = turple.offset
 let element = turple.element
 if i < textCount {
 unorderedTextRects[sortedTexts[i]] = element.size
 }
 }
 var orderedTextRects = [TextRect]()
 zip(lines, rects).forEach {
 let text = $0.0
 var rect = $0.1
 rect.size = unorderedTextRects[text] ?? .zero
 orderedTextRects.append( TextRect(text, rect))
 }
 
 self.delegate?.ocrService(self, didGetTextRects: orderedTextRects)
 
 self.queue.async {
 self.isBusy = false
 }
 
 }
 }
 }
 
 
 
 }
 */


extension CGImage {
    var uiImage: UIImage { return UIImage(cgImage: self)}
}

extension UIImage {
    var greysCaled: UIImage {
        
        let saturationFilter = Luminance()
        //        let adaptive = AdaptiveThreshold()
        //        adaptive.blurRadiusInPixels = 15
        
        return self.filterWithOperation(saturationFilter)
    }
}


extension CGFloat {
    func roundToNearest(_ x : CGFloat) -> CGFloat {
        return x * (self / x).rounded()
    }
    var int: Int { return Int(self)}
}
extension Int {
    var cgFloat: CGFloat { return CGFloat(self) }
}

extension Set {
    var array: [Element] { return Array(self)}
}


extension BidirectionalCollection where Iterator.Element: Equatable {
    
    typealias Element = Self.Iterator.Element
    
    func after(_ item: Element, loop: Bool = false) -> Element? {
        if let itemIndex = self.firstIndex(of: item) {
            let lastItem: Bool = (index(after:itemIndex) == endIndex)
            if loop && lastItem {
                return self.first
            } else if lastItem {
                return nil
            } else {
                return self[index(after:itemIndex)]
            }
        }
        return nil
    }
    
    func before(_ item: Element) -> Element? {
        if let itemIndex = self.firstIndex(of: item) {
            guard itemIndex != startIndex else { return nil }
            return self[index(before: itemIndex)]
        }
        return nil
    }
}

extension CGAffineTransform {
    func scale() -> Double {
        return sqrt(Double(self.a * self.a + self.c * self.c))
    }
    
    func translation() -> CGPoint {
        return CGPoint(x: self.tx, y: self.ty)
    }
}
extension UIImage {
    // 2
    func scaledImage(_ maxDimension: CGFloat) -> UIImage? {
        // 3
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        // 4
        if size.width > size.height {
            scaledSize.height = size.height / size.width * scaledSize.width
        } else {
            scaledSize.width = size.width / size.height * scaledSize.height
        }
        // 5
        UIGraphicsBeginImageContext(scaledSize)
        draw(in: CGRect(origin: .zero, size: scaledSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        // 6
        return scaledImage
    }
}
