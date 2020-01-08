//
//  Words.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 17/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation

final class Words {
    
    static let shahred = Words()
    var words = [String]()
    
    func load() {
        guard let url = Bundle.main.url(forResource: "one", withExtension: ".txt") else { return }
        if let string = try?  String.init(contentsOf: url) {
            words = string.words()
        }
    }
}
