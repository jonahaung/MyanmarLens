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
import NaturalLanguage

protocol OcrServiceDelegate: class {
    func ocrService(_ service: OcrService, didGetStableTextRects textRects: [TextRect])
    func ocrService(_ service: OcrService, didFailedCapture quad: Quadrilateral?)
    func ocrService(_ service: OcrService, didCapture quad: Quadrilateral?)
    func ocrService(_ service: OcrService, didGetImage image: UIImage)
    func ocrService(_ service: OcrService, didCaptureRectangle quad: Quadrilateral?)
    var detectedLanguage: NLLanguage { get set  }
}

final class OcrService: NSObject {
    
    static var roi = CGRect(x: 0, y: 0.23, width: 1, height: 0.70)
    weak var delegate: OcrServiceDelegate?
    private let context = CIContext(options: nil)
    private lazy var tessrect: SwiftyTesseract = {
        $0.preserveInterwordSpaces = true
        return $0
    }(SwiftyTesseract(language: .burmese))
    private lazy var textRequest: VNRecognizeTextRequest = { [unowned self] in
        $0.usesLanguageCorrection = true
        $0.recognitionLevel = .fast
        return $0
    }(VNRecognizeTextRequest(completionHandler: textHandler(request:error:)))
    private let videoLayer: CameraPriviewLayer
    private let overlayView: OverlayView
    var isMyanmar: Bool { return delegate?.detectedLanguage == .burmese }
    private var currentQuads = [Quadrilateral]()
    private let objectTracker: ObjectTracker<String> = ObjectTracker(reliability: .verifiable)
    init(_overlayView: OverlayView) {
        overlayView = _overlayView
        videoLayer = _overlayView.videoPreviewLayer
        super.init()
    }
    
    deinit {
        clear()
        print("OCR")
    }
    
    func clear() {
        objectTracker.resetAll()
        textRequest.recognitionLevel = .fast
        currentQuads.removeAll()
        currentImageBuffer = nil
    }
    
    private (set) weak var currentImageBuffer: CVImageBuffer?
}



// Video Input
extension OcrService: VideoServiceDelegate {
    
    
    
    func videoService(_ service: VideoService, didOutput buffer: CVImageBuffer) {
        
        self.currentImageBuffer = buffer
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up, options: [:])
        do {
            try requestHandler.perform([self.textRequest])
        }catch { print(error )}
        
    }
    
    private func textHandler(request: VNRequest, error: Error?) {
        guard var results = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        
        results = results.filter{ OcrService.roi.intersects($0.boundingBox)}
        
        let quads = results.map(Quadrilateral.init)
        
        let textRects = quads.map{($0.text, $0.frame)}.filter{ !$0.0.isEmpty }
        
        if textRects.isEmpty {
            delegate?.ocrService(self, didCapture: nil)
            return
        }
        
        let rect = textRects.map{ $0.1 }.reduce(CGRect.null, {$0.union($1)}).insetBy(dx: -0.02, dy: -0.02).intersection(OcrService.roi)
        
        var quad = Quadrilateral(rect)
       
        let texts = textRects.map{ $0.0 }.joined(separator: " ").lowercased()
        let domainLanguage = NSLinguisticTagger.dominantLanguage(for: texts)
        let language = domainLanguage == "en" ? NLLanguage.english.localName : NLLanguage.burmese.localName
        objectTracker.logFrame(objects: [language])
        if let stable = objectTracker.getStableItem() {
            textRequest.recognitionLevel = .accurate
            let isMyanmar = stable == NLLanguage.burmese.localName
            let nlLanguage = isMyanmar ? NLLanguage.burmese : .english
            quad.text = stable
            delegate?.detectedLanguage = nlLanguage
        } else {
            textRequest.recognitionLevel = .fast
        }
        
        quad.imageBuffer = currentImageBuffer
        quad.quadrilaterals = quads
        delegate?.ocrService(self, didCapture: quad)
        currentQuads.append(quad)
    }
    
    func capture() {
       
        guard let quad = currentQuads.last,
            let imageBuffer = quad.imageBuffer,
            let textRects = quad.textRects,
            let cgImage = self.getCurrentCgImage(buffer: imageBuffer)
            else {
                delegate?.ocrService(self, didFailedCapture: nil)
                return
        }
        textRequest.cancel()
        let uiImage = UIImage(cgImage: cgImage)
        delegate?.ocrService(self, didGetImage: uiImage)
        
       
        
        var imageRects = [(UIImage, CGRect)]()
        var finalResults = [TextRect]()
        autoreleasepool {
            textRects.forEach { x in
                if let im = self.cropImage(cgImage: cgImage, rect: x.1.scaleUp(scaleUp: 0.01).normalized()) {
                    let rect = x.1.applying(self.videoLayer.layerTransform)
                    if self.isMyanmar {
                        imageRects.append((im, rect))
                    } else {
                        let tr = TextRect(x.0, rect, _isMyanmar: false, _image: im)
                        finalResults.append(tr)
                    }
                }
            }
        }
        
        if !self.isMyanmar {
            self.delegate?.ocrService(self, didGetStableTextRects: finalResults)
            return
        }
        
        let group = DispatchGroup()
        for imageRect in imageRects {
            group.enter()
            self.tessrect.performOCR(on: imageRect.0) { str in
                if let txt = str?.filteredSmallWords, txt.utf16.count > 3 {
                    let textRect = TextRect(txt, imageRect.1, _isMyanmar: true, _image: imageRect.0)
                    finalResults.append(textRect)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .global(qos: .utility)) { [weak self] in
            guard let self = self else { return }
            self.delegate?.ocrService(self, didGetStableTextRects: finalResults)
            
        }
        
    }
    
    func detectRectangle() {
        guard let quad = currentQuads.last, let buffer = quad.imageBuffer else { return }
        ObjectDetector.rectangle(for: buffer, intersect: .zero) {[weak self] quad in
            guard let self = self else { return }
            self.delegate?.ocrService(self, didCaptureRectangle: quad)
        }
    }
    
}

// Others
extension OcrService {
    
    private func cropImage(cgImage: CGImage, rect: CGRect) -> UIImage? {
        if let cropped = cgImage.cropping(to: rect.viewRect(for: VideoService.videoSize).scaleUp(scaleUp: 0.01)) {
            return UIImage(cgImage: cropped, scale: UIScreen.main.scale, orientation: .up)
        }
        return nil
    }
    
    private func getCurrentCgImage(buffer: CVPixelBuffer) -> CGImage? {
        let ciImage = CIImage(cvImageBuffer: buffer)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
    
}


