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
            
            
            if textRect.translatedText == nil {
                let text = textRect._text.trimmed
                if let found = self.cached[text] {
                    textRect.translatedText = found
                    DispatchQueue.global(qos: .background).async {
                        next()
                    }
                }else {
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
                            result = result.replacingOccurrences(of: "39", with: "'")
                            textRect.translatedText = result
                            self.cached[textRect._text] = result
                        }
                        next()
                    }
                }
                
                
            } else {
                next()
            }
        }
    }
}
