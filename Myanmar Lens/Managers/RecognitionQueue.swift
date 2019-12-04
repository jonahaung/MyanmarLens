//
//  SwiftyTesseract.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 20/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//


struct RecognitionQueue<T: Hashable> {
    private var values: [T]
    
    let size: Int
    
    var allValuesMatch: Bool {
        guard size == values.count else { return false }
        return Set(values).count == 1
    }
    
    init(maxElements: Int) {
        size = maxElements
        values = [T]()
    }
    
    mutating func enqueue(_ value: T) {
        values.append(value)
        if values.count > size {
            dequeue()
        }
    }
    
    @discardableResult
    mutating func dequeue() -> T? {
        if values.isEmpty { return nil }
        return values.remove(at: 0)
    }
    
    mutating func clear() {
        values.removeAll()
    }
    
}

extension RecognitionQueue {
    init(desiredReliability: RecognitionReliability) {
        self.init(maxElements: desiredReliability.numberOfResults)
    }
}
