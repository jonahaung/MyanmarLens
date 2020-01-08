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
    
    
    private var queue = DispatchQueue(label: "OcrService.queue", attributes: .concurrent)
    
    static var roi = CGRect(x: 0, y: 0.5, width: 1, height: 0.5)
    private var tessrect = SwiftyTesseract(language: .burmese)
    private var boxTracker: RecognitionQueue<Box> = RecognitionQueue(reliability: .stable)
    private let sentenceTracker: ObjectTracker<String> = ObjectTracker(reliability: .raw)
    private let overlayView: OverlayView
    private let requestHandler = VNSequenceRequestHandler()
    weak var pixelBuffer: CVPixelBuffer?
    var isBusy = false
    private let videoLayer: AVCaptureVideoPreviewLayer
    private var currentImage: CGImage?
    var semaphore = DispatchSemaphore(value: 1)
    
    var objects: Set<TextRect> = Set<TextRect>()
    
    private var lastObservation: VNRectangleObservation?
    
    init(_overlayView: OverlayView) {
        overlayView = _overlayView
        videoLayer = _overlayView.videoPreviewLayer
        tessrect.preserveInterwordSpaces = true
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
    var isMyanmar = false {
        didSet {
            boxTracker.updateReliability(reliability: isMyanmar ? .stable : .verifiable)
        }
    }
    var transform = CGAffineTransform.identity
}

// Eng
extension OcrService {
    private func textHandler(request: VNRequest, error: Error?) {
        guard var results = request.results as? [VNRecognizedTextObservation], results.count > 0 else {
            semaphore.signal()
            return }
        results = results.filter{ rectangelRequest.regionOfInterest.normalized().contains($0.boundingBox )}
        
        
        var textRects = [TextRect]()
        for result in results {
            if let top = result.topCandidates(1).first {
                let text = top.string.include(in: .englishAlphabets)
                
                let xMin = result.topLeft.x
                let xMax = result.topRight.x
                let yMin = result.topLeft.y
                let ymax = result.bottomLeft.y
                
                let frame = CGRect(x: xMin, y: ymax, width: abs(xMin - xMax), height: abs(yMin-ymax)).applying(transform)
                
                let newTextRect = TextRect(text, frame)
                textRects.append(newTextRect)
            }
        }
        
        let sumRect = textRects.map{$0.rect}.reduce(CGRect.null) { $0.union($1)}.inset(by: UIEdgeInsets(top: -7, left: -5, bottom: -7, right: -10))
        if sumRect.area > currentBox.cgrect.area {
            var box = Box(sumRect, trashold: 5)
            currentBox = box
            box.update(isBusy ? .Busy : .Unstable)
            delegate?.ocrService(self, didUpdate: box)
            boxTracker.clear()
        }
        
        
        guard isBusy == false else {
            semaphore.signal()
            return
        }
        
        boxTracker.enqueue(currentBox)
        guard boxTracker.allValuesMatch, var stable = boxTracker.dequeue() else {
            semaphore.signal()
            return
        }
        
        stable.update(.Stable)
        delegate?.ocrService(self, didUpdate: stable)

        queue.async {
            self.isBusy = true
        }
        
        self.delegate?.ocrService(self, didGetStableTextRects: textRects)
        
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
        guard let results = request.results as? [VNTextObservation], results.count > 0 else {
            semaphore.signal()
            return
        }
        var rects = [CGRect]()
       
        for result in results {

            let xMin = result.topLeft.x
            let xMax = result.topRight.x
            let yMin = result.topLeft.y
            let ymax = result.bottomLeft.y
            let rect = CGRect(x: xMin, y: ymax, width: abs(xMin - xMax), height: abs(yMin-ymax)).applying(transform)
            rects.append(rect)
        }
        
        let sumRect = rects.reduce(CGRect.null) { $0.union($1)}.inset(by: UIEdgeInsets(top: -7, left: -5, bottom: -7, right: -10))
        if sumRect.area > currentBox.cgrect.area {
            var box = Box(sumRect, trashold: 5)
            currentBox = box
            box.update(isBusy ? .Busy : .Unstable)
            delegate?.ocrService(self, didUpdate: box)
            boxTracker.clear()
        }
        
        
        guard isBusy == false else {
            semaphore.signal()
            return
        }
        
        boxTracker.enqueue(currentBox)
        guard boxTracker.allValuesMatch, var stable = boxTracker.dequeue() else {
            semaphore.signal()
            return
        }
        boxTracker.clear()
        
        queue.async { [weak self] in
            guard let self = self else { return }
            self.isBusy = true
            
            guard let cgImage = self.getCurrentCgImage(), let cropped = self.cropImage(cgImage: cgImage, rect: stable.cgrect.applying(self.transform.inverted()).normalized())?.greysCaled  else {
                self.isBusy = false
                self.semaphore.signal()
                return
            }
            
            stable.update(.Stable)
            self.delegate?.ocrService(self, didUpdate: stable)
            autoreleasepool {
                self.tessrect.performOCR(on: cropped) {[weak self] result in
                    guard let self = self else { return }
                    var lines: [String] = []
                    if let sentence = result, sentence.isWhitespace == false {
                        lines = sentence.lines().map{ $0.cleanUpMyanmarTexts() }.filter{ $0.isWhitespace == false && $0.utf16.count > 3 }
                    }
                    guard self.isBusy else {
                        self.semaphore.signal()
                        return
                    }
                    let filtered = rects.filter{ stable.cgrect.contains($0.origin)}
                    let sorted = self.nonMaxSuppression(rects: filtered, threshold: 0.1, limit: lines.count).sorted{ $0.origin.y < $1.origin.y }
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
                        var size = UIFont.myanmarFont.withSize(avHeight * 1.2).sizeOfString(string: text, constrainedToWidth: stable.cgrect.width)
                        size.height = avHeight
                        frame.size = size
                        frame.origin.x = max(stable.cgrect.origin.x, frame.origin.x)
                        if frame.maxX > stable.cgrect.maxX {
                            frame.origin.x = stable.cgrect.minX
                        }
                        
                        y += avHeight + spacing
                        
                        let existings = self.objects.filter{ $0.isSimilterText(_text: text)}
                        if let existing = existings.first {
                
                            existing.rect = frame
                            textRects.append(existing)
                            self.objects.update(with: existing)
                        }else {
                            let newTextRect = TextRect(text, frame)
                            textRects.append(newTextRect)
                            self.objects.insert(newTextRect)
                        }
                    }
                    self.delegate?.ocrService(self, didGetStableTextRects: textRects)
                }
                
            }
        }
        
        
        
    }
}

// Video Input
extension OcrService: VideoServiceDelegate {
    func handle(ciImage: CIImage) {
        _ = semaphore.wait(wallTimeout: .distantFuture)
        queue.sync { [weak self] in
            let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
            self?.currentImage = cgImage
            guard let self = self else { return }
            self.pixelBuffer = pixelBuffer
            let request = isMyanmar ? rectangelRequest : textRequest
            var requestOptions: [VNImageOption : Any] = [:]
            
            if let cameraIntrinsicData = CMGetAttachment(ciImage, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
                requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
            }
            
            let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, orientation: .up, options: requestOptions)
            do {
                try imageRequestHandler.perform([request])
            } catch {
                print(error)
            }
        }
    }
    func videoService(_ service: VideoService, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        _ = semaphore.wait(wallTimeout: .distantFuture)
        if isBusy {
            service.fps = 1
        }
        
        if let buffer = pixelBuffer {
            queue.sync { [weak self] in
                
                guard let self = self else { return }
                self.pixelBuffer = pixelBuffer
                let request = isMyanmar ? rectangelRequest : textRequest
                var requestOptions: [VNImageOption : Any] = [:]
                
                if let cameraIntrinsicData = CMGetAttachment(buffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
                    requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
                }
                
                let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up, options: requestOptions)
                do {
                    try imageRequestHandler.perform([request])
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func handleSequenceRequestUpdate(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let newObservation = request.results?.first as? VNRectangleObservation else {
                return}
            
            self.lastObservation = newObservation
            
            let rect = newObservation.boundingBox.applying(self.transform)
            self.overlayView.highlightLayer.frame = rect
        }
    }
    
    private func drawBoundingBox(_ points: [CGPoint], color: CGColor) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.fillColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        layer.strokeColor = color
        layer.lineWidth = 2
        let path = UIBezierPath()
        path.move(to: points.last!)
        points.forEach { point in
            path.addLine(to: point)
        }
        layer.path = path.cgPath
        return layer
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
    func start(){
        rectangelRequest.regionOfInterest = OcrService.roi.normalized()
        self.reset()
        updateTransform()
        queue.async {
            self.isBusy = false
        }
    }
    
    func stop() {
        objects.removeAll()
        textRequest.cancel()
        rectangelRequest.cancel()
        queue.async {
            self.isBusy = true
        }
    }
    
    func reset() {
        currentBox = CGRect.zero.box
        
        boxTracker.clear()
        semaphore.signal()
        print("restart")
    }
}
