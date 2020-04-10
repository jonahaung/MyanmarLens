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
 private var cached = [TextRect]()
final class TranslateService {
    
    weak var delegate: TranslateServiceDelegate?

    func handle(textRects: [TextRect]) {
        let pair = userDefaults.languagePair
       
        if pair.source == pair.target {
            DispatchQueue.main.async {
                self.delegate?.translateService(self, didFinishTranslation: textRects)
            }
            
            return
        }
    
        textRects.forEach { x in
            if x.translatedText == nil {
                if let found = (cached.filter{ $0 == x && $0.translatedText != nil}).first {
                    x.translatedText = found.translatedText
                   
                }else if let existing = existing(x._text.lowercased(), language: pair.target.rawValue){
                    x.translatedText = existing
                    cached.append(x)
                }
            }
        }
        
        
        let wifii = Translator.shared.getWiFiAddress()
        let email = Random.emailAddress
    
        textRects.filter{ $0.translatedText == nil }.asyncForEach(completion: {[weak self] in
            guard let self = self else { return }
            self.delegate?.translateService(self, didFinishTranslation: textRects)
        }) { (textRect, next) in
            Translator.shared.translate(text: textRect._text.lowercased(), from: pair.source, to: pair.target, wifiiAddress: wifii, email: email) {(result, err) in
               
                if let err = err {
                    print(err.localizedDescription)
                    next()
                    return
                }
                let isMyanmar = result?.EXT_isMyanmarCharacters == true
                if var result = result?.lowercased(), !result.isWhitespace {
                    if isMyanmar {
                        result = result.cleanUpMyanmarTexts()
                    }else {
                        result = EngTextCorrector.shared.correct(text: result)
                    }
                    textRect.translatedText = result
                    cached.append(textRect)
                }
                next()
            }
        }
    }
    
    private func existing(_ text: String, language: String) -> String? {
        return TranslatePair.find(from: text, language: language, context: PersistanceManager.shared.container.newBackgroundContext())?.to
    }
}
