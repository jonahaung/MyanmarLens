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
    func ocrService(_ service: OcrService, didUpdate rect: CGRect)
    func ocrService(_ service: OcrService, didGetStable rect: CGRect, image: UIImage?)
}

final class OcrService: NSObject {
    
    static var roi = CGRect(x: 0, y: 0.28, width: 1, height: 0.68)
    
    weak var delegate: OcrServiceDelegate?
    
    private let context = CIContext(options: nil)
    private var tessrect = SwiftyTesseract(language: .burmese)
    
    private let videoLayer: AVCaptureVideoPreviewLayer
    let semaphore = DispatchSemaphore(value: 1)
    var isMyanmar = false
    var transform = CGAffineTransform.identity
    private let containerInsets = UIEdgeInsets(top: -12, left: -5, bottom: -12, right: -10)
    
    private var isStop = false
    private var isStable = false
    
    var imageBuffer: CVImageBuffer?
    var cgImage: CGImage?
    let overlayView: OverlayView
    init(_overlayView: OverlayView) {
        overlayView = _overlayView
        videoLayer = _overlayView.videoPreviewLayer
        tessrect.preserveInterwordSpaces = true
        super.init()
    }
    
    deinit {
        stop()
        print("OCR")
    }
    
    private lazy var textRequest: VNRecognizeTextRequest = {
        let x = VNRecognizeTextRequest(completionHandler: textHandler)
        x.usesLanguageCorrection = true
        x.recognitionLevel = .accurate
        x.preferBackgroundProcessing = true
        x.usesCPUOnly = true
        return x
    }()

}

// Eng
extension OcrService {

    private func textHandler(request: VNRequest, error: Error?) {
       
        guard var results = request.results as? [VNRecognizedTextObservation],  let cgImage = self.cgImage else { return }
        let roi = OcrService.roi
        results = results.filter{ roi.contains($0.boundingBox )}
        
        var finalResults = [TextRect]()
        var textRects = [(String, CGRect)]()
      
        var isNumber = 0
        for result in results {
            if let top = result.topCandidates(1).first {
                let text = top.string
                guard !text.isWhitespace else { continue }
                if text.rangeOfCharacter(from: .decimalDigits) != nil {
                    isNumber += 1
                }
                let xMin = result.topLeft.x
                let xMax = result.topRight.x
                let yMin = result.topLeft.y
                let ymax = result.bottomLeft.y
                
                var frame = CGRect(x: xMin, y: ymax, width: abs(xMin - xMax), height: abs(yMin-ymax))
                frame = frame.applying(transform).integral
                textRects.append((text, frame))
            }
        }

        var imageRects = [(UIImage, CGRect)]()
        
        autoreleasepool {
            let invertedTransform = self.transform.inverted()
            textRects.forEach { x in
                if let im = self.cropImage(cgImage: cgImage, rect: x.1.applying(invertedTransform).normalized()) {

                    if self.isMyanmar {
                        imageRects.append((im, x.1))
                    } else {
                        let tr = TextRect(x.0, x.1, _isMyanmar: false, _image: im)
                        finalResults.append(tr)
                    }
                }
            }
        }
        
       
        guard isMyanmar else {
            self.delegate?.ocrService(self, didGetStableTextRects: finalResults)
            
            return
        }
        
        let group = DispatchGroup()
        for ir in imageRects {
            group.enter()
            let image = ir.0
            tessrect.performOCR(on: image) { str in
                if let txt = str?.filteredSmallWords, txt.utf16.count > 3 {
                    let textRect = TextRect(txt, ir.1, _isMyanmar: true, _image: image)
                    finalResults.append(textRect)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.delegate?.ocrService(self, didGetStableTextRects: finalResults)
        }
        
    }
}

// Video Input
extension OcrService: VideoServiceDelegate {
    
    func captureOutput(didOutput sampleBuffer: CVImageBuffer) {
      
        guard !isStop else { return }
        if !isStable{
            if let cgImage = self.getCurrentCgImage(buffer: sampleBuffer) {
                isStable = true
                semaphore.wait()
                self.cgImage = cgImage
                let ui = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
                delegate?.ocrService(self, didGetStable: .zero, image: ui)
                let handler = VNImageRequestHandler(cvPixelBuffer: sampleBuffer, orientation: .up, options: [:])
                do {
                    try handler.perform([textRequest])
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func next() {
        
        semaphore.signal()
    }

}

// Others
extension OcrService {
    
    private func cropImage(cgImage: CGImage, rect: CGRect) -> UIImage? {
        if let cropped = cgImage.cropping(to: rect.viewRect(for: VideoService.videoSize)) {
            return UIImage(cgImage: cropped, scale: UIScreen.main.scale, orientation: .up)
        }
        return nil
    }
    
    private func getCurrentCgImage(buffer: CVPixelBuffer) -> CGImage? {
        let ciImage = CIImage(cvImageBuffer: buffer)
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
        updateTransform()
        semaphore.signal()
        isStable = false
        isStop = false
    }
    
    func stop() {
        isStop = true
        imageBuffer = nil
        isStable = false
    }
    
}


extension UIImage {
    func colour() -> UIColor {
        var bitmap = [UInt8](repeating: 0, count: 4)
        if #available(iOS 9.0, *) {
            // Get average color.
            let context = CIContext()
            let inputImage: CIImage = ciImage ?? CoreImage.CIImage(cgImage: cgImage!)
            let extent = inputImage.extent
            let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
            let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: inputExtent])!
            let outputImage = filter.outputImage!
            let outputExtent = outputImage.extent
            assert(outputExtent.size.width == 1 && outputExtent.size.height == 1)
            
            // Render to bitmap.
            context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: CIFormat.RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        } else {
            // Create 1x1 context that interpolates pixels when drawing to it.
            let context = CGContext(data: &bitmap, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            let inputImage = cgImage ?? CIContext().createCGImage(ciImage!, from: ciImage!.extent)
            
            // Render to bitmap.
            context.draw(inputImage!, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        
        // Compute result.
        let result = UIColor(red: CGFloat(bitmap[0]) / 255.0, green: CGFloat(bitmap[1]) / 255.0, blue: CGFloat(bitmap[2]) / 255.0, alpha: CGFloat(bitmap[3]) / 255.0)
        return result
    }
    
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}
extension String {
    var filteredSmallWords: String {
        return self.words().map{ $0.trimmed }.filter{ $0.utf16.count > 3 }.joined(separator: " ")
    }
}
