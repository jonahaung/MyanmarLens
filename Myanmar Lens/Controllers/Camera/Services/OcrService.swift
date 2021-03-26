//
//  VisionService.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 4/1/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//


import Vision
import AVFoundation
import SwiftyTesseract

protocol OcrServiceDelegate: class {
    func ocrService(_ service: OcrService, didGetTextRects textRects: [TextRect])
    func ocrService(displayNoResult service: OcrService)
}
final class OcrService: NSObject {
    
    private lazy var textRequest: VNRecognizeTextRequest = {
        $0.recognitionLevel = .accurate
        $0.usesLanguageCorrection = true
        return $0
    }(VNRecognizeTextRequest(completionHandler: textsHandler(request:error:)))
    
    private lazy var tessrect: SwiftyTesseract = {
        $0.preserveInterwordSpaces = true
        return $0
    }(SwiftyTesseract(language: .burmese))

    static var regionOfInterest = CGRect(x: 0, y: 0.2, width: 1, height: 0.70)
    weak var delegate: OcrServiceDelegate?
    
    private let context = CIContext(options: nil)
    
    var currentPixelBuffer: CVPixelBuffer?
    private let videoLayer: CameraPriviewLayer
    // Init
    init(_ _overlayView: OverlayView) {
        videoLayer = _overlayView.videoPreviewLayer
        super.init()
    }
    
    deinit {
        textRequest.cancel()
        print("OCR")
    }
}

extension OcrService {
    
    private func handleBurmese(with cvPixelBuffer: CVPixelBuffer) {
        let ciImage = cvPixelBuffer.ciImage
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let image = UIImage(cgImage: cgImage)
        let color = image.getColors()
        
        
        _ = tessrect.performOCR(on: image)
        let blocks = try! tessrect.recognizedBlocks(for: .textline).get()
        let scaleTransform = CGAffineTransform(scaleX: self.videoLayer.containerSize.width/image.size.width, y: self.videoLayer.containerSize.height/image.size.height)
    
        let textRects = blocks.map{ TextRect($0.text.cleanUpMyanmarTexts(), $0.boundingBox.applying(scaleTransform), _isMyanmar: true, _colors: color) }
        delegate?.ocrService(self, didGetTextRects: textRects)
        
//        switch tessrect.performOCR(on: image) {
//            case let .success(string):
//                print(string.cleanUpMyanmarTexts())
//                switch tessrect.recognizedBlocks(for: .textline) {
//                case let .success(blocks):
//                    let textRects = blocks.map{ TextRect($0.text.cleanUpMyanmarTexts(), $0.boundingBox.applying(scaleTransform), _isMyanmar: true, _colors: color) }
//
//                    DispatchQueue.main.async {
//                        self.delegate?.ocrService(self, didGetTextRects: textRects)
//                    }
//                case let .failure(error):
//                    print(error)
//                }
//
//            case .failure:
//                print("Error")
//        }
        
    }
    
    func handle(with cvPixelBuffer: CVPixelBuffer) {
        currentPixelBuffer = cvPixelBuffer
        if userDefaults.sourceLanguage == .burmese {
            handleBurmese(with: cvPixelBuffer)
        } else {
            textRequest.cancel()
            let handler = VNImageRequestHandler(cvPixelBuffer: cvPixelBuffer, orientation: .up)
            do {
                try handler.perform([textRequest])
            }catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func textsHandler(request: VNRequest, error: Error?) {
        guard
            let ciImage = currentPixelBuffer?.ciImage,
            let cgImage = context.createCGImage(ciImage, from: ciImage.extent),
            let observations = request.results as? [VNRecognizedTextObservation],
            observations.count > 0 else {
                displayNoResults()
                return
        }
        
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let containerSize = videoLayer.containerSize
        
        var textRects = [TextRect]()
        
        for result in observations {
            guard let top = result.topCandidates(1).first else {
                continue
            }
            let visionRect = result.boundingBox
            
            let text = top.string
            
            let imageRect = visionRect.normalized().viewRect(for: imageSize).insetBy(dx: 0, dy: -6)
            
            guard let cropped = cgImage.cropping(to: imageRect) else {
                continue
            }
            
            let uiImage = UIImage(cgImage: cropped)
            let textRect = TextRect(text, visionRect.normalized().viewRect(for: containerSize), _isMyanmar: false, _colors: uiImage.getColors())
            textRects.append(textRect)
        }
        delegate?.ocrService(self, didGetTextRects: textRects)
    }
    
    private func displayNoResults() {
        delegate?.ocrService(displayNoResult: self)
    }
}

extension OcrService {
    func cancel() {
        textRequest.cancel()
    }
}
