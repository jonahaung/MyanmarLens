//
//  VisionService.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 4/1/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//


import Vision
import AVKit
import SwiftyTesseract
import NaturalLanguage

//var myanmar = Set<String>()

protocol OcrServiceDelegate: class {
    func ocrService(_ service: OcrService, didGetStableTextRects textRects: [TextRect])
    func ocrService(_ service: OcrService, didCapture quad: Quadrilateral?, isStable: Bool)
    func ocrService(_ service: OcrService, willCapture quad: Quadrilateral?, with image: UIImage?)
    var detectedLanguage: NLLanguage { get set  }
    var isAutoScan: Bool { get }
}

final class OcrService: NSObject {
    
    private let languageDetector = LanguageDetector_1()
    private lazy var tessrect: SwiftyTesseract = {
        $0.preserveInterwordSpaces = true
        return $0
    }(SwiftyTesseract(language: .burmese))
    
    static var regionOfInterest = CGRect(x: 0, y: 0.20, width: 1, height: 0.80)
    weak var delegate: OcrServiceDelegate?
    
    private lazy var context = CIContext(options: nil)
    
    private let videoLayer: CameraPriviewLayer
    
    var isMyanmar: Bool { return delegate?.detectedLanguage == .burmese }
    var isAutoScan: Bool { return delegate?.isAutoScan == true }
    private let funnel = RectangleFeaturesFunnel()
    private var textRequest: TextRequest?
    
    static let textDetector = CIDetector(ofType: CIDetectorTypeText, context: CIContext(options: nil), options: [CIDetectorAccuracyLow: CIDetectorAccuracyLow])
    
    private var isDetecting = false
    private var isStable: Bool = false
    
    private let noRectangleThreshold = 3
    private var noRectangleCount = 0
    private var displayedQuad: Quadrilateral?
    
    private let foundTextTreshold = 3
    private var foundTextsCount = 0
   
    private var cachedPixelBuffers = [UUID: CVPixelBuffer]()
    
    // Init
    init(_overlayView: OverlayView) {
        videoLayer = _overlayView.videoPreviewLayer
        super.init()
        createTextRequest()
    }
    
    deinit {
        reset()
        print("OCR")
    }
    
    func reset() {
        textRequest?.cancel()
        funnel.currentAutoScanPassCount = 0
        displayedQuad = nil
        isStable = false
        foundTextsCount = 0
        noRectangleCount = 0
        cachedPixelBuffers.removeAll()
        isDetecting = true
    }
    
    func start() {
        isDetecting = true
    }
    
    func capture() {
        textRequest?.cancel()
        if let displayedQuad = displayedQuad, displayedQuad.textRects != nil, let id = displayedQuad.id {
            
            
            capture(quad: displayedQuad, id: id)
        }
    }
}

// VideoServiceDelegate {

extension OcrService: VideoServiceDelegate {

    func videoService(_ service: VideoService, didOutput buffer: CVImageBuffer) {
        guard isDetecting else { return }
        if isStable {
            performTextRequest(buffer)
        } else {
            performRectangleRequest(buffer)
        }
    }
}


// Text
extension OcrService {
    
    private func createTextRequest() {
        
        textRequest = TextRequest { [weak self] (request, err) in
            guard let self = self else { return }
            
            guard
                let textRequest = request as? TextRequest,
                let id = textRequest.id,
                let results = textRequest.results as? [VNRecognizedTextObservation],
                results.count > 0
                else {
                    self.isStable = false
                    self.foundTextsCount = 0
                    return
                }
            
            let filteredResults = results.filter{ OcrService.regionOfInterest.contains($0.boundingBox)}
            
            let textRects: [(String, CGRect)] = {
                var x = [(String, CGRect)]()
                filteredResults.forEach {
                    if let top = $0.topCandidates(1).first {
                        x.append((top.string, $0.boundingBox))
                    }
                }
                return x
            }()
            self.performTextRects(textRects, with: id)
            
        }
    }
    
    private func performTextRects(_ textRects: [(String, CGRect)], with id: UUID) {
        guard textRects.count > 0 else {
            isStable = false
            foundTextsCount = 0
            return
        }
        
        let rect = textRects.map{ $0.1 }.reduce(CGRect.null, {$0.union($1)}).scaleUp(scaleUp: 0.002).intersection(OcrService.regionOfInterest).applying(self.videoLayer.layerTransform)
        var quad = Quadrilateral(rect, id: id, textRects: textRects, text: "")
        
        if userDefaults.isLanguageDetectionEnabled {
            let text = textRects.map{ $0.0 }.joined(separator: " ").lowercased()
            do {
                let language = try languageDetector.prediction(text: text)
                let sourceLanguage = language.label == "Myanmar" ? NLLanguage.burmese : .english
                delegate?.detectedLanguage = sourceLanguage
                
                quad.applyText(text: sourceLanguage.localName)
            }catch {
                self.isStable = false
                print(error.localizedDescription)
                return
            }
        }
        
        
        foundTextsCount += 1
        
        displayRectangleResult(quad: quad)
        displayedQuad = quad
        if (foundTextsCount > foundTextTreshold && isAutoScan) {
            capture(quad: quad, id: id)
        }
    }
    
    private func performTextRequest(_ buffer: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up, options: [:])
        
        if let request = self.textRequest {
            let id = UUID()
            request.id = id
            self.cachedPixelBuffers[id] = buffer
            do {
                try handler.perform([request])
            }catch {
                print(error )
            }
        }
    }
}



// Capturing

extension OcrService {
    
    private func capture(quad: Quadrilateral, id: UUID) {
        isDetecting = false
        foundTextsCount = 0
        guard
            let textRects = quad.textRects,
            let buffer = cachedPixelBuffers[id],
            let cgImage = self.getCurrentCgImage(buffer: buffer)
        else {
               displayRectangleResult(quad: nil)
                return
        }

    
         delegate?.ocrService(self, willCapture: quad, with: UIImage(cgImage: cgImage))
        
        
        var myanmarObjects = [(UIImage, CGRect)]()
        var resultObjects = [TextRect]()
        let isBurmese = isMyanmar
        
        autoreleasepool {[weak self] in
            guard let self = self else { return }
            textRects.forEach { tr in
                if let cropped = self.cropImage(cgImage: cgImage, rect: tr.1.normalized()) {
                    let rect = tr.1.applying(self.videoLayer.layerTransform)
                    if isBurmese {
                        myanmarObjects.append((cropped, rect))
                    } else {
                        resultObjects.append(TextRect(tr.0, rect, _isMyanmar: isBurmese, _image: cropped))
                    }
                }
            }
        }
        if isBurmese {
            let dispatchQroup = DispatchGroup()
            for object in myanmarObjects {
                dispatchQroup.enter()
                
                self.tessrect.performOCR(on: object.0) { result in
                    
                    if let txt = result?.filteredSmallWords, txt.utf16.count > 3 {
                        
                        let textRect = TextRect(txt, object.1, _isMyanmar: true, _image: object.0)
                        resultObjects.append(textRect)
                    }
                    dispatchQroup.leave()
                }
            }
            
            dispatchQroup.notify(queue: .main) { [weak self] in
                guard let self = self else { return }
                self.delegate?.ocrService(self, didGetStableTextRects: resultObjects)
            }
        } else {
            delegate?.ocrService(self, didGetStableTextRects: resultObjects)
        }
        
    }
}


// Rectangle
extension OcrService {
    
    private func performRectangleRequest(_ buffer: CVPixelBuffer) {
        let ciImage = CIImage(cvImageBuffer: buffer)
        guard let rectangleFeatures = OcrService.textDetector?.features(in: ciImage) as? [CITextFeature], rectangleFeatures.count > 0  else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.noRectangleCount += 1
                
                if self.noRectangleCount > self.noRectangleThreshold {
                
                    self.funnel.currentAutoScanPassCount = 0
                    
                    // Remove the currently displayed rectangle as no rectangles are being found anymore
                    self.displayedQuad = nil
                    self.delegate?.ocrService(self, didCapture: nil, isStable: self.isStable)
                }
            }
            
            return
        }
        let scale = videoLayer.bounds.width / ciImage.extent.width
        let roi = OcrService.regionOfInterest.applying(videoLayer.layerTransform)
        let rect = rectangleFeatures
            .map{ $0.rectInBounds(videoLayer.bounds, scale: scale)}
            .filter{roi.contains($0)}
            .reduce(CGRect.null, {$0.union($1)})
                        
        let quad = Quadrilateral(rect)
        noRectangleCount = 0
        
        
        self.funnel.add(quad, currentlyDisplayedRectangle: displayedQuad) {[weak self] (result, resultQuad) in
            guard let self = self, !self.isStable else { return }
            let shouldAutoScan = (result == .showAndAutoScan)
            self.displayRectangleResult(quad: resultQuad)
            if shouldAutoScan {
                self.isStable = true
            }
            
        }
    }
    
    
    @discardableResult private func displayRectangleResult(quad: Quadrilateral?) -> Quadrilateral? {
        displayedQuad = quad

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.delegate?.ocrService(self, didCapture: quad, isStable: self.isStable)
        }
        
        return quad
    }
}


// Others
extension OcrService {
    
    private func cropImage(cgImage: CGImage, rect: CGRect) -> UIImage? {
        if let cropped = cgImage.cropping(to: rect.viewRect(for: VideoService.videoSize).scaleUp(scaleUp: 0.02)) {
            return UIImage(cgImage: cropped, scale: UIScreen.main.scale, orientation: .up)
        }
        return nil
    }
    
    private func getCurrentCgImage(buffer: CVPixelBuffer) -> CGImage? {
        let ciImage = CIImage(cvImageBuffer: buffer)
        return  context.createCGImage(ciImage, from: ciImage.extent)
    }
    
}


