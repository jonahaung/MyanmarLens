//
//  MyanmarReSegment.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 27/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation

class MyanmarReSegment {
    
    static let shared = MyanmarReSegment()
    private static let RESEGMENT_REGULAR_EX = "(?:(?<!္)([က-ဪဿ၊-၏]|[၀-၉]+|[^က-၏]+)(?![ှျ]?[့္်]))"
    
    static func segment(_ text : String) -> [String] {
        let outputs  = text.replacingOccurrences(of: RESEGMENT_REGULAR_EX, with: "𝕊$1", options: [.regularExpression, .caseInsensitive])
        var ouputArray = outputs.components(separatedBy: "𝕊")
        
        if (ouputArray.count > 0) {
            ouputArray.remove(at: 0)
        }
        
        return ouputArray
    }
    
}
