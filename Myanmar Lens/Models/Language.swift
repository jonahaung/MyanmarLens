//
//  Language.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 23/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import NaturalLanguage
import Vision
typealias LanguagePair = (source: NLLanguage, target: NLLanguage)

struct Languages {
    static let targetLanguages: [NLLanguage] = [.arabic, .arabic, .armenian, .bengali, .bulgarian, .burmese, .catalan, .czech, .cherokee, .croatian, .dutch, .danish, .dutch, .english, .french, .finnish, .german, .greek, .georgian, .gujarati, .hindi, .hebrew, .hungarian, .italian, .icelandic, .indonesian, .japanese, .khmer, .korean, .kannada, .lao, .malay, .marathi, .malayalam, .mongolian, .oriya, .polish, .persian, .punjabi, .portuguese, .russian, .romanian, .spanish, .slovak, .swedish, .sinhalese, .simplifiedChinese, .thai, .tamil, .telugu, .tibetan, .turkish, .traditionalChinese, .urdu, .ukrainian, .vietnamese]
    static let sourceLanguages: [NLLanguage] = [.burmese, .english]
}

extension NLLanguage {
    
    var localName: String {
        return Locale.current.localizedString(forIdentifier: self.rawValue) ?? ""
    }
}
