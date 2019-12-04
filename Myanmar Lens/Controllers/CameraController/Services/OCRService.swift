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
    func ocrService(_ service: OCRService, didGetResults textRects: [TextRect])
}

final class OCRService {
    
    private let tessract = SwiftyTesseract.init(language: .burmese, bundle: Bundle.main, engineMode: .lstmOnly)
    weak var delegate: OCRServiceDelegate?
    init() {
        tessract.preserveInterwordSpaces = false
        
    }
    func handle(imageRects: [ImageRect]) {
        var textRects = [TextRect]()
        imageRects.asyncForEach(completion: {[weak self] in
            guard let self = self else { return }
            self.delegate?.ocrService(self, didGetResults: textRects)
        }) { (imageRect, next) in
            tessract.performOCR(on: imageRect.0) {string in
                if let string = string?.cleanUpMyanmarTexts(), !string.isWhitespace {
                    textRects.append(TextRect(string, imageRect.1))
                }
                next()
            }
        }
    }
    
    
}
