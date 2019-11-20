//
//  Localizer.swift
//  mMsgr
//
//  Created by Aung Ko Min on 30/12/18.
//  Copyright © 2018 Aung Ko Min. All rights reserved.
//

import UIKit

final class TextCorrector {
    
    static var shared: TextCorrector {
        struct Singleton {
            static let instance = TextCorrector()
        }
        return Singleton.instance
    }
    
    private lazy var correctingRules: [NSDictionary] = {
        if let path = Bundle.main.path(forResource: "TextCorrect", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options:[])
                return jsonResult as? [NSDictionary] ?? []
            } catch {
                return []
            }
        }
        return []
    }()

    
    func correct(text: String) -> String {
        let rule = correctingRules
        var output = text
        for dic in rule {
            let from = dic["from"] as! String
            let to = dic["to"] as! String
            let range = output.startIndex ..< output.endIndex
            output = output.replacingOccurrences(of: from, with: to, options: .regularExpression, range: range)
        }
        return output
    }

}



let textChecker = UITextChecker()
extension String {
    
    func detectMispelled(for language: String) -> String {
        var text = self
        
        let nsString = NSString(string: text)
        let stringRange = NSRange(location: 0, length: nsString.length)
        var offset = 0
        
        repeat {
            let wordRange = textChecker.rangeOfMisspelledWord(in: text, range: stringRange, startingAt: offset, wrap: false, language: language)
            guard wordRange.location != NSNotFound else {
                break
            }
            
            let misspelled = nsString.substring(with: wordRange)
            text = text.replacingOccurrences(of: misspelled, with: "\"\(misspelled)\"", options: .literal, range: nil)
            offset = wordRange.upperBound
        } while true
        return text
    }
}
