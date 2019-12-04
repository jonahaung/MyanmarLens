//
//  CameraController+Helpers.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 30/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit
import Vision

extension VNTextObservation {

    var rect: CGRect {
        let x = boundingBox
        return CGRect(x: x.origin.x, y: 1 - x.origin.y - x.height, width: x.size.width, height: x.size.height)
    }

}

extension CGRect {
    
    func localRect(for bounds: CGRect) -> CGRect {
        let n = self
        let x = n.origin.x * bounds.size.width
        let y = n.origin.y * bounds.size.height
        let width = n.width * bounds.size.width
        let height = n.height * bounds.size.height
        return CGRect(x: x, y: y, width: width, height: height).integral
    }
    
    var area: CGFloat {
        return self.width * self.height
    }
    
    static func sum(rects: [CGRect]) -> CGRect {
        var result = CGRect.zero
        
        for x in rects {
            result = x.union(result)
        }
        return result
    }
}


extension UIViewController {
    func add(childController: UIViewController) {
        childController.willMove(toParent: self)
        view.addSubview(childController.view)
        childController.didMove(toParent: self)
    }
}

extension Sequence {

    func asyncForEach(completion: @escaping () -> (), block: (Iterator.Element, @escaping () -> ()) -> ()) {
        let group = DispatchGroup()
        let innerCompletion = { group.leave() }
        for x in self {
            group.enter()
            block(x, innerCompletion)
        }
        group.notify(queue: DispatchQueue.main, execute: completion)
    }
    
    func all(_ condition: (Iterator.Element) -> Bool) -> Bool {
        for x in self where !condition(x) {
            return false
        }
        return true
    }
    
    func some(_ condition: (Iterator.Element) -> Bool) -> Bool {
        for x in self where condition(x) {
            return true
        }
        return false
    }
}

extension DispatchQueue {
  convenience init(queueLabel: DispatchQueue.Label) {
    self.init(label: queueLabel.rawValue)
  }
  
  enum Label: String {
    case session, videoOutput
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
    
    func resizeImage(targetSize: CGSize) -> UIImage {
      let size = self.size
      let widthRatio  = targetSize.width  / size.width
      let heightRatio = targetSize.height / size.height
      let newSize = widthRatio > heightRatio ?  CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
      let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

      UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
      self.draw(in: rect)
      let newImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()

      return newImage!
    }
}
extension Character {
    func getSimilarCharacterIfNotIn(allowedChars: String) -> Character {
        let conversionTable = [
            "s": "S",
            "S": "5",
            "5": "S",
            "o": "O",
            "Q": "O",
            "O": "0",
            "0": "O",
            "l": "I",
            "I": "1",
            "1": "I",
            "B": "8",
            "8": "B"
        ]
        // Allow a maximum of two substitutions to handle 's' -> 'S' -> '5'.
        let maxSubstitutions = 2
        var current = String(self)
        var counter = 0
        while !allowedChars.contains(current) && counter < maxSubstitutions {
            if let altChar = conversionTable[current] {
                current = altChar
                counter += 1
            } else {
                // Doesn't match anything in our table. Give up.
                break
            }
        }
        
        return current.first!
    }
}
