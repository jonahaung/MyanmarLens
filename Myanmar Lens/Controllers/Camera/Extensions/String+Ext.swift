//
//  String+Ext.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 27/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation
import NaturalLanguage

extension CharacterSet {
    
    static let removingCharacters = CharacterSet(charactersIn: "|+*#%;:&^$@!~.,'`|_ၤ”“")
    
    static let myanmarAlphabets = CharacterSet(charactersIn: "ကခဂဃငစဆဇဈညတဒဍဓဎထဋဌနဏပဖဗဘမယရလ၀သဟဠအ").union(.whitespacesAndNewlines)
    static let myanmarCharacters2 = CharacterSet(charactersIn: "ါာိီုူေဲဳဴဵံ့း္်ျြွှ")
    static var englishAlphabets = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ")
    static var lineEnding = CharacterSet(charactersIn: ".,?!;:။…\n\t")
}
extension String {
    
    var language: String {

        return NSLinguisticTagger.dominantLanguage(for: self) ?? ""
    }
    func cleanUpMyanmarTexts() -> String {
        var texts = self
        if let range = self.rangeOfCharacter(from: CharacterSet.removingCharacters) {
            texts = self.replacingCharacters(in: range, with: " ")
        }
        
//        let segs = MyanmarReSegment.segment(self)
//        print(segs)
//        var filtered = [String]()
//        segs.forEach { seg in
//            var new = seg
//            if replaces.contains(seg) {
//                new = " "
//            }
//            filtered.append(new)
//        }
        return MyanmarTextCorrector.shared.correct(text: texts.trimmed)
    }
    
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var urlDecoded: String {
        return removingPercentEncoding ?? self
    }
    
    var urlEncoded: String {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? self
    }
    
    var isWhitespace: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var withoutSpacesAndNewLines: String {
        return replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "")
    }
}
extension String {
    func exclude(in set: CharacterSet) -> String {
        let filtered = unicodeScalars.lazy.filter { !set.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }
    func include(in set: CharacterSet) -> String {
        let filtered = unicodeScalars.lazy.filter { set.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }
    
    func lines() -> [String] {
        var result = [String]()
        enumerateLines { line, _ in
            result.append(line)
        }
        return result
    }
    
    func words() -> [String] {
        let comps = components(separatedBy: CharacterSet.whitespacesAndNewlines)
        return comps.filter { !$0.isWhitespace }
    }
    
    public func contains(_ string: String, caseSensitive: Bool = true) -> Bool {
        if !caseSensitive {
            return range(of: string, options: .caseInsensitive) != nil
        }
        return range(of: string) != nil
    }
    
}

extension String {
    
    var EXT_isMyanmarCharacters: Bool {
        return self.rangeOfCharacter(from: CharacterSet.myanmarAlphabets) != nil
    }
    var EXT_isEnglishCharacters: Bool {
        return self.rangeOfCharacter(from: CharacterSet.englishAlphabets) != nil
    }
    
    var firstWord: String {
        return words().first ?? self
    }
    
    func lastWords(_ max: Int) -> [String] {
        return Array(words().suffix(max))
    }
    var lastWord: String {
        return words().last ?? self
    }
    
    var firstLetterCapitalized: String {
        guard !isEmpty else { return self }
        return prefix(1).capitalized + dropFirst()
    }
}
