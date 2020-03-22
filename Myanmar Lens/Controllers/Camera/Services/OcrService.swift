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
    func ocrService(_ service: OcrService, didFailedCapture quad: Quadrilateral?)
    func ocrService(_ service: OcrService, didCapture quad: Quadrilateral?, lastQuad: Quadrilateral?, isStable: Bool)
    func ocrService(_ service: OcrService, didOutput image: UIImage, with sourceLanguage: NLLanguage)
    var detectedLanguage: NLLanguage { get set  }
}

final class OcrService: NSObject {
    
    private let languageDetector = LanguageDetector_1()
    
    static var regionOfInterest = CGRect(x: 0, y: 0.13, width: 1, height: 0.80)
    
    weak var delegate: OcrServiceDelegate?
    
    private let context = CIContext(options: nil)
    
    private let videoLayer: CameraPriviewLayer
    
    var isMyanmar: Bool { return delegate?.detectedLanguage == .burmese }
    
    private lazy var tessrect: SwiftyTesseract = {
        $0.preserveInterwordSpaces = true
        return $0
    }(SwiftyTesseract(language: .burmese))
    
    private var cachedPixelBuffers = [UUID: CVPixelBuffer]()
    
    private var cachedQuads = [UUID: Quadrilateral]()
    
    // Init
    init(_overlayView: OverlayView) {
        videoLayer = _overlayView.videoPreviewLayer
        super.init()
    }
    
    deinit {
        reset()
        print("OCR")
    }
    
    func reset() {
        currentRequest?.cancel()
        cachedQuads.removeAll()
        cachedPixelBuffers.removeAll()
    }
    var currentRequest: VNRequest?
}



// Video Input
extension OcrService: VideoServiceDelegate {
    

    func videoService(_ service: VideoService, didOutput buffer: CVImageBuffer) {
        
        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up, options: [:])
        
        let request = ObjectDetector.textRequest(for: buffer) {[weak self] (x, err) in
            guard let self = self else { return }
            guard let textRequest = x as? TextRequest, var results = x.results as? [VNRecognizedTextObservation], results.count > 0 else {
                DispatchQueue.main.async {
                    self.delegate?.ocrService(self, didFailedCapture: nil)
                }
                return
            }
            results = results.filter{ OcrService.regionOfInterest.contains($0.boundingBox)}
            
            let textRects: [(String, CGRect)] = {
                var x = [(String, CGRect)]()
                results.forEach {
                    if let top = $0.topCandidates(1).first {
                        x.append((top.string, $0.boundingBox))
                    }
                }
                return x
            }()
            
            if textRects.count == 0 {
                DispatchQueue.main.async {
                    self.delegate?.ocrService(self, didFailedCapture: nil)
                }
                return
            }
            
            let rect = textRects.map{ $0.1 }.reduce(CGRect.null, {$0.union($1)}).insetBy(dx: -0.02, dy: -0.02)
            let text = textRects.map{ $0.0 }.joined(separator: " ").lowercased()
            let quad = Quadrilateral(rect, id: textRequest.id, textRects: textRects, text: text)
            self.cachedQuads[textRequest.id] = quad
            DispatchQueue.main.async {
                self.delegate?.ocrService(self, didCapture: quad, lastQuad: nil, isStable: false)
            }
        }
        self.cachedPixelBuffers[request.id] = buffer
        do {
            try handler.perform([request])
        }catch { print(error )}
        currentRequest = request
    }
    
    
    func capture(id: UUID) {
        currentRequest?.cancel()
        guard
            let quad = cachedQuads[id],
            let textRects = quad.textRects,
            let buffer = cachedPixelBuffers[id],
            let cgImage = self.getCurrentCgImage(buffer: buffer)
            else { return }
        
        
        let uiImage = UIImage(cgImage: cgImage)
        
        do {
            let language = try self.languageDetector.prediction(text: quad.text)
            let sourceLanguage = language.label == "Myanmar" ? NLLanguage.burmese : .english
            DispatchQueue.main.async {
                self.delegate?.ocrService(self, didOutput: uiImage, with: sourceLanguage)
            }
        }catch {
            print(error.localizedDescription)
        }
        
        
        var myanmarObjects = [(UIImage, CGRect)]()
        var resultObjects = [TextRect]()
        
        autoreleasepool {
            textRects.forEach { x in
                if let cropped = self.cropImage(cgImage: cgImage, rect: x.1.normalized()) {
                    let rect = x.1.applying(self.videoLayer.layerTransform)
                    if self.isMyanmar {
                        myanmarObjects.append((cropped, rect))
                    } else {
                        let tr = TextRect(x.0, rect, _isMyanmar: false, _image: cropped)
                        resultObjects.append(tr)
                    }
                }
            }
        }
        
        if !isMyanmar {
            DispatchQueue.main.async {
                self.delegate?.ocrService(self, didGetStableTextRects: resultObjects)
            }
            return
        }
        
        let dispatchQroup = DispatchGroup()
        for object in myanmarObjects {
            
            dispatchQroup.enter()
            
            tessrect.performOCR(on: object.0) { result in
                
                if let txt = result?.filteredSmallWords, txt.utf16.count > 3 {
                    
                    let textRect = TextRect(txt, object.1, _isMyanmar: true, _image: object.0)
                    resultObjects.append(textRect)
                }
                dispatchQroup.leave()
            }
        }
        
        dispatchQroup.notify(queue: .main) { [weak self] in
            
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.delegate?.ocrService(self, didGetStableTextRects: resultObjects)
            }
        }
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


