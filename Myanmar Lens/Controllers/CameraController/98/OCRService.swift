//
//  TessractServce.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 2/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation
import SwiftyTesseract

protocol OCRServiceDelegate: class {
    func ocrService(_ service: OCRService, didGetResults translateTextRects: [TextRect])
}

final class OCRService {
    
    private let tessract = SwiftyTesseract.init(language: .burmese, bundle: Bundle.main, engineMode: .lstmOnly)
    weak var delegate: OCRServiceDelegate?
  
    
    init() {
        tessract.preserveInterwordSpaces = false
        tessract.minimumCharacterHeight = 10
    }
    
    
    func handle(imageRects: [ImageRect]) {
        var textRects = [TextRect]()
        imageRects.asyncForEach(completion: {[weak self] in
            guard let self = self else { return }
            self.delegate?.ocrService(self, didGetResults: textRects)
        }) { (imageRect, next) in
            let scaledImage = imageRect.image
            tessract.performOCR(on: scaledImage) {string in
                if let string = string?.trimmedNoneBurmeseCharacters.trimmingCharacters(in: .newlines), !string.isWhitespace {
                    textRects.append(TextRect(text: string, rect: imageRect.rect))
                }
                next()
            }
        }
    }
    
    
}
extension UIImage {
    
  func scaledImage(_ maxDimension: CGFloat) -> UIImage? {
    // 3
    var scaledSize = CGSize(width: maxDimension, height: maxDimension)
    // 4
    if size.width > size.height {
      scaledSize.height = size.height / size.width * scaledSize.width
    } else {
      scaledSize.width = size.width / size.height * scaledSize.height
    }
    // 5
    UIGraphicsBeginImageContext(scaledSize)
    draw(in: CGRect(origin: .zero, size: scaledSize))
    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    // 6
    return scaledImage
  }
}
