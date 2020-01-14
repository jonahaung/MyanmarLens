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
}

final class OcrService: NSObject {
    
    static var roi = CGRect(x: 0, y: 0.25, width: 1, height: 0.75)
    
    weak var delegate: OcrServiceDelegate?
    
    private let context = CIContext(options: nil)
    private var tessrect = SwiftyTesseract(language: .burmese)
    private let requestHandler = VNSequenceRequestHandler()
    private(set) weak var pixelBuffer: CVPixelBuffer?
    private let videoLayer: AVCaptureVideoPreviewLayer
    let semaphore = DispatchSemaphore(value: 1)
    var isMyanmar = false
    private var transform = CGAffineTransform.identity
    private let containerInsets = UIEdgeInsets(top: -12, left: -5, bottom: -12, right: -10)
    private var previousCount = 0
    private var isStop = true
    private var previousContainerRect = CGRect.zero
    
    init(_overlayView: OverlayView) {
        videoLayer = _overlayView.videoPreviewLayer
        tessrect.preserveInterwordSpaces = false
        super.init()
    }
    
    deinit {
        stop()
        print("OCR")
    }
    
    private lazy var textRequest: VNRecognizeTextRequest = {
        let x = VNRecognizeTextRequest(completionHandler: textHandler(request:error:))
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
        guard var results = request.results as? [VNRecognizedTextObservation] else { return }
        results = results.filter{ OcrService.roi.contains($0.boundingBox )}
//        let resultsCount = results.count
//        if resultsCount == 0 {
//            return
//        }
//
//        let diff = abs(resultsCount - previousCount)
//        previousCount = resultsCount
//        guard diff == 0 else { return }
//        
//        if diff > 2 {
//            return
//        }
//        
        var finalResults = [TextRect]()
        var textRects = [(String, CGRect)]()
        
        for result in results {
            if let top = result.topCandidates(1).first {
                let text = top.string
                let xMin = result.topLeft.x
                let xMax = result.topRight.x
                let yMin = result.topLeft.y
                let ymax = result.bottomLeft.y
                
                var frame = CGRect(x: xMin, y: ymax, width: abs(xMin - xMax), height: abs(yMin-ymax))
                frame = frame.applying(transform).integral

                textRects.append((text, frame))
            }
        }
        
        
        let containerRect = textRects.map{$0.1}.reduce(CGRect.null) { $0.union($1)}.inset(by: self.containerInsets)
        
        previousContainerRect = containerRect

        delegate?.ocrService(self, didUpdate: containerRect)

        semaphore.wait()
        guard let cgImage = self.getCurrentCgImage() else {
            semaphore.signal()
            return
        }
    

        
        
        var imageRects = [(UIImage, CGRect)]()
        textRects.forEach { x in
            if let im = self.cropImage(cgImage: cgImage, rect: x.1.applying(self.transform.inverted()).normalized()) {
                if self.isMyanmar {
                    imageRects.append((im, x.1))
                } else {
                    let tr = TextRect(x.0, x.1, _isMyanmar: false, _color: im.averageColor)
                    finalResults.append(tr)
                }
                
            }
        }
        guard isMyanmar else {
            DispatchQueue.main.async {
                self.delegate?.ocrService(self, didGetStableTextRects: finalResults)
            }
            
            return
        }
        
        let group = DispatchGroup()
        
        for ir in imageRects {
            let image = ir.0
            group.enter()
            tessrect.performOCR(on: image) { [weak self] str in
                if let `self` = self, !self.isStop, let txt = str?.filteredSmallWords, txt.utf16.count > 3 {
                    let textRect = TextRect(txt, ir.1, _isMyanmar: true, _color: image.averageColor)
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

extension String {
    var filteredSmallWords: String {
        return self.words().map{ $0.trimmed }.filter{ $0.utf16.count > 3 }.joined(separator: " ")
    }
}
// Video Input
extension OcrService: VideoServiceDelegate {
    func videoService(_ service: VideoService, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?) {
        self.pixelBuffer = pixelBuffer
        guard isStop == false else { return }
        if let buffer = pixelBuffer {
            do {
                try requestHandler.perform([textRequest], on: buffer, orientation: .up)
            } catch {
                print(error)
            }
        }
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
    
    private func getCurrentCgImage() -> CGImage? {
        
        guard let cm = pixelBuffer else { return nil }
        let ciImage = CIImage(cvImageBuffer: cm)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
    
    private func updateTransform() {
        let videoRect = self.videoLayer.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1))
        let visible = videoRect.intersection(self.videoLayer.visibleRect)
        let scaleT = CGAffineTransform(scaleX: visible.width, y: -visible.height)
        let translateT = CGAffineTransform(translationX: visible.minX, y: visible.maxY)
        transform = scaleT.concatenating(translateT)
    }
    
    
    func start(){
        updateTransform()
        semaphore.signal()
        isStop = false
    }
    
    func stop() {
        previousContainerRect = CGRect.zero
        textRequest.cancel()
        isStop = true
    }
    
}


extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
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

}

/*
 private func performOCR(croppedImage: UIImage, _textRects: [(String, CGRect)]) {
     var textRects = _textRects
     tessrect.performOCR(on: croppedImage) {[weak self] result in
         guard let self = self else { return }
         if let sentence = result?.trimmed {
             var lines = [String]()
             sentence.lines().forEach { line in
                 let filterdLine = line.words().filter{ $0.utf16.count > 3 }.map{ $0.trimmed }.joined(separator: " ")
                 if !filterdLine.isEmpty {
                     lines.append(filterdLine)
                 }
                 
             }
             repeat {
                 var sorted = textRects.sorted{ $0.1.height > $1.1.height }
                 if lines.count == textRects.count { break }
                 sorted.removeLast()
                 textRects = sorted
             }while ( lines.count < textRects.count )
             
             guard lines.count == textRects.count else {
                 self.currentImage = nil
                 self.semaphore.signal()
                 return
             }
             
             var objects = [TextRect]()
             
             zip(textRects.sorted{ $0.1.origin.y < $1.1.origin.y}, lines).forEach { (tr, line) in
                 objects.append(TextRect(line, tr.1, _isMyanmar: true, _color: self.averageColor))
             }
             
             self.delegate?.ocrService(self, didGetStableTextRects: objects)
         }
     }
 }
 */

extension CGRect: Hashable {
    public func hash(into hasher: inout Hasher) {
        width.hashValue.hash(into: &hasher)
        height.hashValue.hash(into: &hasher)
        origin.y.hashValue.hash(into: &hasher)
        origin.x.hashValue.hash(into: &hasher)
    }
}
