//
//  StringTracker.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 24/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation

class ObjectTracker<T: Hashable> {
    var frameIndex: Int64 = 0

    typealias Observation = (lastSeen: Int64, count: Int64)
    
    var seenStrings = [T: Observation]()
    var bestCount = Int64(0)
    var bestString: [T] = []
    var quality = 0 {
        didSet {
            resetLoop = Int64(quality * 5)
        }
    }
    var resetLoop = Int64(0)
    
    init(reliability: Accurcy) {
        quality = reliability.numberOfResults
    }
    
    func logFrame(objects: [T]) {
        for string in objects {
            if seenStrings[string] == nil {
                seenStrings[string] = (lastSeen: Int64(0), count: Int64(-1))
            }
            seenStrings[string]?.lastSeen = frameIndex
            seenStrings[string]?.count += 1
//            print("Seen \(string) \(seenStrings[string]?.count ?? 0) times")
        }
    
        var obsoleteStrings = [T]()

        for (string, obs) in seenStrings {
            // Remove previously seen text after 30 frames (~1s).
            if obs.lastSeen < frameIndex - resetLoop {
                obsoleteStrings.append(string)
            }
            
            let count = obs.count
            if !obsoleteStrings.contains(string) && count > bestCount {
                bestCount = Int64(count)
                bestString.append(string)
            }
        }
       
        for string in obsoleteStrings {
            seenStrings.removeValue(forKey: string)
        }
        
        frameIndex += 1
    }
    
    func getStableItem() -> [T]? {
        if bestCount >= quality {
            return bestString
        } else {
            return nil
        }
    }
    
    func reset(object: T) {
        seenStrings.removeValue(forKey: object)
        bestCount = 0
        bestString = []
    }
    func resetAll() {
        seenStrings.removeAll()
        bestCount = 0
        bestString = []
    }
}
