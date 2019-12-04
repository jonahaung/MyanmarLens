//
//  String+Ext.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 27/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation

extension CharacterSet {
    
    static let removingCharacters = CharacterSet(charactersIn: "()|+*#%;:&^$@!~.,'`|_ၤ()”“")
    
    static let myanmarAlphabets = CharacterSet(charactersIn: "ကခဂဃငစဆဇဈညတဒဍဓဎထဋဌနဏပဖဗဘမယရလ၀သဟဠအဣဧဤဩဥ။")
    static let myanmarCharacters2 = CharacterSet(charactersIn: "ါာိီုူေဲဳဴဵံ့း္်ျြွှ")
    static var englishAlphabets = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 ")
    static var lineEnding = CharacterSet(charactersIn: ".,?!;:။…\n\t")
}

extension String {
    
    func cleanUpMyanmarTexts() -> String {
        let words = self.words()
        let filtered = words.filter{ RegexParser.regularExpression(for: RegexParser.unicodePattern)!.matches($0)}
        return MyanmarTextCorrector.shared.correct(text: filtered.joined(separator: " ")).exclude(in: .removingCharacters)
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
        return comps.filter { !$0.isEmpty }
    }
    
    public func contains(_ string: String, caseSensitive: Bool = true) -> Bool {
        if !caseSensitive {
            return range(of: string, options: .caseInsensitive) != nil
        }
        return range(of: string) != nil
    }
    
    var myanmarSegments: [String] {
        let regex = RegexParser.regularExpression(for: RegexParser.myanmarWordsBreakerPattern)
        
        let modString = regex?.stringByReplacingMatches(in: self, options: [], range: self.nsRange(of: self), withTemplate: "𝕊$1")
        return modString?.components(separatedBy: "𝕊").filter{ !$0.isWhitespace } ?? self.components(separatedBy: .whitespaces)
    }
    
    var trimmedNoneBurmeseCharacters: String {
        return RegexParser.regularExpression(for: RegexParser.myanmarWordsBreakerPattern)?.stringByReplacingMatches(in: self, options: [], range: self.wholeNSRange, withTemplate: "$1").exclude(in: .removingCharacters) ?? String()
    }
    
    var wholeNSRange: NSRange { return nsRange(of: self) }
    func nsRange(of word: String) -> NSRange {
        if let wordRange = self.range(of: word) {
            return NSRange(wordRange, in: self)
        }
        
        return NSRange(location: 0, length: 0)
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
}
