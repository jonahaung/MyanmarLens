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
                if let found = (cached.filter{ $0 == x}).first {
                    x.translatedText = found.text
                   
                }else if let existing = existing(x.text.lowercased(), language: pair.target.rawValue){
                    x.translatedText = existing
                    cached.append(x)
                }
            }
        }
        
        let isMyanmar = pair.source == .burmese
        let wifii = Translator.shared.getWiFiAddress()
        let email = Random.emailAddress
        let queryPair = "\(pair.source.rawValue)|\(pair.target.rawValue)"
        textRects.filter{ $0.translatedText == nil }.asyncForEach(completion: {[weak self] in
            guard let self = self else { return }
            self.delegate?.translateService(self, didFinishTranslation: textRects)
        }) { (textRect, next) in
            Translator.shared.translate(text: textRect.text, from: pair.source, to: pair.target, pair: queryPair, wifiiAddress: wifii, email: email) {(result, err) in
               
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
