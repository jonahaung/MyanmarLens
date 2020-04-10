//
//  PerspectiveService.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 8/4/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import UIKit
import Vision
import AVFoundation
import SwiftyTesseract

protocol LiveOcrServiceDelegate: class {
    func liveOcrService(_ service: LiveOcrService, didGet quad: Quadrilateral)
    func liveOcrService(_ service: LiveOcrService, didTrack quad: Quadrilateral)
}

final class LiveOcrService {
    
    private var textRequest: TextRequest!
    weak var delegate: LiveOcrServiceDelegate?
    private let sequenceHandler = VNSequenceRequestHandler()
    weak var pixelBuffer: CVImageBuffer?
    var currentTextRects = [(String, CGRect)]()
    private var lastObservation: VNDetectedObjectObservation?
    private let trackingLayer: CAShapeLayer
    private let videoLayer: CameraPriviewLayer
    
    init(_ _overlayView: OverlayView) {
        trackingLayer = _overlayView.trackLayer
        videoLayer = _overlayView.videoPreviewLayer
        textRequest = TextRequest()
    }
    
    private func textHandler(request: VNRequest, error: Error?) {
        guard
            var results = request.results as? [VNRecognizedTextObservation],
            results.count > 0,
            let ciImage = pixelBuffer?.ciImage,
            let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent)
            else {
                currentTextRects.removeAll()
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
            currentTextRects.removeAll()
            return
        }
        let previous = currentTextRects
        
        let rect = textRects.map{ $0.1 }.reduce(CGRect.null, {$0.union($1)})
//        let newObservation = VNDetectedObjectObservation(boundingBox: rect)
//        lastObservation = newObservation
        var quad = Quadrilateral(rect)
//        quad.cgImage = cgImage.cropping(to: rect.normalized().viewRect(for: ciImage.extent.size))
//        trackingLayer.contents = quad.cgImage
        if userDefaults.sourceLanguage != .burmese {
            quad.textRects = textRects
            delegate?.liveOcrService(self, didGet: quad)
        } else {
            var myanmarTextRects = [(String, CGRect)]()
            if previous.count == textRects.count {
                for (i, v) in textRects.enumerated() {
                    myanmarTextRects.append((previous[i].0, v.1))
                }
                quad.textRects = myanmarTextRects
                self.currentTextRects = myanmarTextRects
                self.delegate?.liveOcrService(self, didGet: quad)
            } else {
                currentTextRects.removeAll()
                let imageSize = ciImage.extent.size
                
                let tessrect = SwiftyTesseract(language: .burmese)
                let dispatchQroup = DispatchGroup()
                
                textRects.forEach {
                    dispatchQroup.enter()
                    let visionRect = $0.1
                    let imageRect = visionRect.normalized().viewRect(for: imageSize).insetBy(dx: 0, dy: -6)
                    if let cropped = cgImage.cropping(to: imageRect) {
                        let uiImage = UIImage(cgImage: cropped)
                        tessrect.performOCR(on: uiImage) { result in
                            if let txt = result?.cleanUpMyanmarTexts() {
                                myanmarTextRects.append((txt, visionRect))
                            }
                            dispatchQroup.leave()
                        }
                    }else {
                        dispatchQroup.leave()
                    }
                }
                dispatchQroup.notify(queue: .main) { [weak self] in
                    guard let self = self else { return }
                    quad.textRects = myanmarTextRects
                    self.currentTextRects = myanmarTextRects
                    self.delegate?.liveOcrService(self, didGet: quad)
                }
            }
        }
    }
    
    func handle(_ pixelBuffer: CVPixelBuffer) {
        
        self.pixelBuffer = pixelBuffer
    
        if let observation = lastObservation {
            let request = VNTrackObjectRequest(detectedObjectObservation: observation, completionHandler: self.handleVisionRequestUpdate)
            request.trackingLevel = .fast
            do {
                try sequenceHandler.perform([request], on: pixelBuffer)
            }catch {
                print(error.localizedDescription)
            }
        }
        
        textRequest.cancel()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        do {
            try handler.perform([textRequest])
        }catch {
            print(error.localizedDescription)
        }
        if textRequest.results != nil {
            textHandler(request: textRequest, error: nil)
        }
    }
    
    func track(observation: VNDetectedObjectObservation) {
        lastObservation = observation
    }
    
    private func handleVisionRequestUpdate(_ request: VNRequest, error: Error?) {
        
        DispatchQueue.main.async {
            guard let newObservation = request.results?.first as? VNDetectedObjectObservation else { return }
            self.lastObservation = newObservation
            let rect = newObservation.boundingBox.scaleUp(scaleUp: 0.02).applying(self.videoLayer.layerTransform)
            let pathh = CGMutablePath()
            pathh.addRoundedRect(in: rect, cornerWidth: 10, cornerHeight: 10)
            self.trackingLayer.path = pathh
            
        }
    }
}

extension LiveOcrService {
    private func observeTexts(_ observation: VNDetectedObjectObservation) {
        if let buffer = pixelBuffer {
            let ciImage = buffer.ciImage
            if let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent), let cropped = cgImage.cropping(to: observation.boundingBox.normalized().viewRect(for: ciImage.extent.size)) {
                //                trackingLayer.contents = cropped
                let request = TextRequest()
                let handler = VNImageRequestHandler(cgImage: cropped, orientation: .up)
                do {
                    try handler.perform([request])
                }catch {
                    print(error.localizedDescription)
                }
                
                guard let results = request.results as? [VNRecognizedTextObservation],
                    results.count > 0 else {
                        return
                }
                
                var textRects = [TextRect]()
                let isMyanmar = userDefaults.sourceLanguage == .burmese
                for result in results {
                    guard let top = result.topCandidates(1).first else {
                        continue
                    }
                    let text = top.string
                    let boundingBox = result.boundingBox
                    let imageRect = boundingBox.normalized().viewRect(for: CGSize(width: cropped.width, height: cropped.height))
                    guard let crp = cropped.cropping(to: imageRect) else {
                        continue
                    }
                    let uiImage = UIImage(cgImage: crp, scale: 2, orientation: .up)
                    let colors = uiImage.getColors()
                    let textRect = TextRect(text, boundingBox.normalized().viewRect(for: observation.boundingBox.applying(videoLayer.layerTransform).size), _isMyanmar: isMyanmar, _colors: colors)
                    let box = BoundingBox()
                    trackingLayer.addSublayer(box.shapeLayer)
                    trackingLayer.addSublayer(box.textLayer)
                    box.show(textRect: textRect)
                    textRects.append(textRect)
                }
            }
        }
    }
}
