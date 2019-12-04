//
//  Language.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 23/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import NaturalLanguage
import Vision
typealias LanguagePair = (NLLanguage, NLLanguage)

struct Languages {
    static let all: [NLLanguage] = [.arabic, .arabic, .armenian, .bengali, .bulgarian, .burmese, .catalan, .czech, .cherokee, .croatian, .dutch, .danish, .dutch, .english, .french, .finnish, .german, .greek, .georgian, .gujarati, .hindi, .hebrew, .hungarian, .italian, .icelandic, .indonesian, .japanese, .khmer, .korean, .kannada, .lao, .malay, .marathi, .malayalam, .mongolian, .oriya, .polish, .persian, .punjabi, .portuguese, .russian, .romanian, .spanish, .slovak, .swedish, .sinhalese, .simplifiedChinese, .thai, .tamil, .telugu, .tibetan, .turkish, .traditionalChinese, .urdu, .ukrainian, .vietnamese]
    static let source: [NLLanguage] = [.burmese, .english]
//    static let source: [NLLanguage] = {
//        let revision = VNRecognizeTextRequest.currentRevision
//
//        do {
//            let possibleLanguages = try VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: revision)
//            print(possibleLanguages)
//            var possibles = possibleLanguages.map{ NLLanguage($0 )}
//            possibles.insert(.burmese, at: 0)
//            return possibles
//        } catch {
//            return []
//        }
//    }()
    
    func visionLanguages() {
        
    }
}

extension NLLanguage {
    
    var description: String {
        return Locale.current.localizedString(forIdentifier: self.rawValue) ?? ""
    }
}
