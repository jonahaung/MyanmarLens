//
//  EngTextCorrector.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 24/3/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import Foundation

final class EngTextCorrector {
    
    static var shared: EngTextCorrector {
        struct Singleton {
            static let instance = EngTextCorrector()
        }
        return Singleton.instance
    }
    
    private lazy var correctingRules: [NSDictionary] = {
        if let path = Bundle.main.path(forResource: "TextCorrectEng", ofType: "json") {
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
        var output = text.lowercased()
        for dic in rule {
            let from = dic["from"] as! String
            let to = dic["to"] as! String
            let range = output.startIndex ..< output.endIndex
            output = output.replacingOccurrences(of: from, with: to, options: .regularExpression, range: range)
        }
        return output
    }

}
