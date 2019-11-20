//
//  RegexParser.swift
//  mMsgr
//
//  Created by Aung Ko Min on 14/1/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation

struct RegexParser {
    
    static let hashtagPattern = "(?:^|\\s|$)#[\\p{L}0-9_]*"
    static let mentionPattern = "(?:^|\\s|$|[.])@[\\p{L}0-9_]*"
    static let urlPattern = "(^|[\\s.:;?\\-\\]<\\(])" +
        "((https?://|www\\.|pic\\.)[-\\w;/?:@&=+$\\|\\_.!~*\\|'()\\[\\]%#,☺]+[\\w/#](\\(\\))?)" +
    "(?=$|[\\s',\\|\\(\\).:;?\\-\\[\\]>\\)])"
    static let phonePattern = "(?:(\\+\\d\\d\\s+)?((?:\\(\\d\\d\\)|\\d\\d)\\s+)?)(\\d{4,5}\\-?\\d{4})"
    static let myanmarWordsBreakerPattern = "(?:(?<!\\u1039)([\\u1000-\\u102A\\u103F\\u104A-\\u104F]|[\\u1040-\\u1049]+|[^\\u1000-\\u104F]+)(?![\\u103E\\u103B]?[\\u1039\\u103A\\u1037]))"
    
    static let myanmarPattern = "[\\u1000-\\u109f\\uaa60-\\uaa7f]+"
    static let khmarPattern = "[\\u1780–\\u17FF]+"
    static let unicodePattern = "[ဃငဆဇဈဉညဋဌဍဎဏဒဓနဘရဝဟဠအ]်|ျ[က-အ]ါ|ျ[ါ-း]|\\u103e|\\u103f|\\u1031[^\\u1000-\\u1021\\u103b\\u1040\\u106a\\u106b\\u107e-\\u1084\\u108f\\u1090]|\\u1031$|\\u1031[က-အ]\\u1032|\\u1025\\u102f|\\u103c\\u103d[\\u1000-\\u1001]|ည်း|ျင်း|င်|န်း|ျာ|စ်|န္တ[က-အ]"
    static let zawGyiPattern = "\\s\\u1031| ေ[က-အ]်|[က-အ]း"
    
    private static var cachedRegularExpressions: [String : NSRegularExpression] = [:]
    
    static func getElements(from text: String, with pattern: String, range: NSRange) -> [NSTextCheckingResult]{
        guard let elementRegex = regularExpression(for: pattern) else { return [] }
        return elementRegex.matches(in: text, options: [.reportCompletion], range: range)
    }
    
    static func regularExpression(for pattern: String) -> NSRegularExpression? {
        if let regex = cachedRegularExpressions[pattern] {
            return regex
        } else if let createdRegex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            cachedRegularExpressions[pattern] = createdRegex
            return createdRegex
        } else {
            return nil
        }
    }
}

extension NSRegularExpression {
    
    func matches(_ string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        let first = self.rangeOfFirstMatch(in: string, options: [], range: range)
        return first.location != NSNotFound
    }
}
