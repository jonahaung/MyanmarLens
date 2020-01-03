//
//  TranslateService.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 4/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation

protocol TranslateServiceDelegate: class {
    func translateService(_ service: TranslateService, didFinishTranslation translateTextRects: [TranslateTextRect])
}
final class TranslateService {
    
    weak var delegate: TranslateServiceDelegate?
    var languagePair = LanguagePair(.burmese, .burmese)
    private var cached: [String: String] = [:]
    
    func handle(textRects: [TextRect]) {
        var results = [TranslateTextRect]()
        textRects.asyncForEach(completion: {[weak self] in
            guard let self = self else { return }
            self.delegate?.translateService(self, didFinishTranslation: results)
        }) { (textRect, next) in
            if let existing = self.cached[textRect.text] {
                results.append(TranslateTextRect(existing, textRect))
                next()

            } else {
                Translator.shared.translate(text: textRect.text, from: languagePair.0.rawValue, to: languagePair.1.rawValue) { (result, err) in
                    if let err = err {
                        print(err)
                        next()
                        return
                    }
                    if let result = result, !result.isWhitespace {
                        results.append(TranslateTextRect(result, textRect))
                        self.cached[textRect.text] = result
                    }
                    next()
                }
            }
            
        }
    }
}
