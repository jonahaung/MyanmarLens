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
    var languagePair: LanguagePair { return userDefaults.languagePair }
    private var cached: [String: String] = [:]
    
    func handle(textRects: [TextRect]) {
        var results = [TranslateTextRect]()
        textRects.asyncForEach(completion: {[weak self] in
            guard let self = self else { return }
            self.delegate?.translateService(self, didFinishTranslation: results)
        }) { [unowned self] (textRect, next) in
            let text = textRect.text.trimmed
            guard !text.isWhitespace else {
                next()
                return
            }
            Translator.shared.translate(text: text, from: languagePair.0.rawValue, to: languagePair.1.rawValue) { [weak self] (result, err) in
                guard let self = self else { return }
                if let err = err {
                    print(err.localizedDescription)
                    next()
                    return
                }
                
                if let result = result, !result.isWhitespace {
                    results.append(TranslateTextRect(translatedText: result, textRect: textRect))
                    self.cached[text] = result
                }
                next()
            }
            
        }
    }
}
