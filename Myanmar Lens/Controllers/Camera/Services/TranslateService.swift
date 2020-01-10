//
//  TranslateService.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 4/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation

protocol TranslateServiceDelegate: class {
    func translateService(_ service: TranslateService, didFinishTranslation textRects: [TextRect])
    var languagePair: LanguagePair { get }
}


final class TranslateService {
    
    weak var delegate: TranslateServiceDelegate?
    
    private var cached: [String: String] = [:]
    
    func handle(textRects: [TextRect]) {
        guard let pair = delegate?.languagePair else { return }
        let isMyanmar = pair.source == .burmese
        textRects.asyncForEach(completion: {[weak self] in
            guard let self = self else { return }
            self.delegate?.translateService(self, didFinishTranslation: textRects)
        }) { [unowned self] (textRect, next) in
            if let found = self.cached[textRect.id] {
                textRect.translatedText = found
                next()
            }else {
                if textRect.isStable && textRect.translatedText == nil {
                    let text = textRect.text.trimmed
                    Translator.shared.translate(text: text, from: pair.0.rawValue, to: pair.1.rawValue) { [weak self] (result, err) in
                        guard let self = self else { return }
                        if let err = err {
                            print(err.localizedDescription)
                            next()
                            return
                        }
                        
                        if var result = result, !result.isWhitespace {
                            if isMyanmar {
                                result = result.cleanUpMyanmarTexts()
                            }
                            textRect.translatedText = result
                            self.cached[textRect.id] = result
                        }
                        next()
                    }
                } else {
                    next()
                }
            }
        }
    }
}
