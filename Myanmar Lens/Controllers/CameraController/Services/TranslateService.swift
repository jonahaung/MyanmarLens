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
}
final class TranslateService {
    weak var delegate: TranslateServiceDelegate?
    var languagePair = LanguagePair(.burmese, .burmese)
    func handle(textRects: [TextRect]) {
        var translated = [TextRect]()
        textRects.asyncForEach(completion: {[weak self] in
            guard let self = self else { return }
            self.delegate?.translateService(self, didFinishTranslation: translated)
        }) { (textRect, next) in
            Translator.shared.translate(text: textRect.0, from: languagePair.0.rawValue, to: languagePair.1.rawValue) { (result, err) in
                if let err = err {
                    print(err)
                    next()
                    return
                }
                if let result = result {
                    translated.append((result, textRect.1))
                }
                next()
            }
        }
    }
}
