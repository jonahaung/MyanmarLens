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
    
    typealias Result = (text: String, visionRect: CGRect, imageRect: CGRect, image: UIImage)
    typealias FinalResult = (text: String, visionRect: CGRect, image: UIImage)
    
    private var textRequest: VNRecognizeTextRequest!
    private let tessrect: SwiftyTesseract = {
        $0.preserveInterwordSpaces = true
        return $0
    }(SwiftyTesseract(language: .burmese))

    static var regionOfInterest = CGRect(x: 0, y: 0.15, width: 1, height: 0.80)
    weak var delegate: OcrServiceDelegate?
    
    private let context = CIContext(options: nil)
    
    var currentPixelBuffer: CVPixelBuffer?
    private let videoLayer: CameraPriviewLayer
    // Init
    init(_ _overlayView: OverlayView) {
        videoLayer = _overlayView.videoPreviewLayer
        super.init()
        textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        textRequest.usesLanguageCorrection = true
    }
    
    deinit {
        textRequest.cancel()
        print("OCR")
    }
}

extension OcrService {
    
    func handle(with cvPixelBuffer: CVPixelBuffer) {
        textRequest.cancel()
        currentPixelBuffer = cvPixelBuffer
        let handler = VNImageRequestHandler(cvPixelBuffer: cvPixelBuffer, orientation: .up)
        
        do {
            try handler.perform([textRequest])
        }catch {
            print(error.localizedDescription)
        }
        if textRequest.results != nil {
            textsHandler(request: textRequest, error: nil)
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
        
        let imageRect = CGRect(origin: .zero, size: CGSize(width: cgImage.width, height: cgImage.height))
    
        var results = [Result]()
        for result in observations {
            guard let top = result.topCandidates(1).first else {
                continue
            }
            let visionRect = result.boundingBox
            guard OcrService.regionOfInterest.contains(visionRect) else {
                continue
            }
            let text = top.string
            
            let imageRect = visionRect.normalized().viewRect(for: imageRect.size).insetBy(dx: 0, dy: -6)
            guard let cropped = cgImage.cropping(to: imageRect) else {
                continue
            }
            let uiImage = UIImage(cgImage: cropped)
            
            let finalResult = Result(text, visionRect, imageRect, uiImage)
            results.append(finalResult)
        }
        var finalResults = [FinalResult]()
        if userDefaults.sourceLanguage == .burmese {
            let dispatchQroup = DispatchGroup()
            for object in results {
                dispatchQroup.enter()
                let image = object.image
                tessrect.performOCR(on: image) { result in
                    
                    if let txt = result?.cleanUpMyanmarTexts() {
                        let finalResult = FinalResult(txt, object.visionRect, image)
                        finalResults.append(finalResult)
                    }
                    dispatchQroup.leave()
                }
            }
            dispatchQroup.notify(queue: .main) { [weak self] in
                guard let self = self else { return }
                self.displayTextRects(finalResults)
            }
        }else {
            finalResults = results.map{ FinalResult($0.text, $0.visionRect, $0.image )}
            self.displayTextRects(finalResults)
        }
    }
    
    private func displayTextRects(_ finalResults: [FinalResult]) {
        let containerSize = videoLayer.containerSize
        var textRects = [TextRect]()
        let isMyanar = userDefaults.sourceLanguage == .burmese
        for finalResut in finalResults {
            let viewRect = finalResut.visionRect.normalized().viewRect(for: containerSize).trashole(trashold: 5)
            let colors = finalResut.image.getColors()
            let textRect = TextRect(finalResut.text, viewRect, _isMyanmar: isMyanar, _colors: colors)
            textRects.append(textRect)
        }
        self.delegate?.ocrService(self, didGetTextRects: textRects)
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
