//
//  StringTracker.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 24/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation

class StringTracker {
    var frameIndex: Int64 = 0

    typealias StringObservation = (lastSeen: Int64, count: Int64)
    
    // Dictionary of seen strings. Used to get stable recognition before
    // displaying anything.
    var seenStrings = [String: StringObservation]()
    var bestCount = Int64(0)
    var bestString = ""
    var minRepeat = Int64(5)
    func logFrame(_ string: String) -> Float {
        if seenStrings[string] == nil {
            seenStrings[string] = (lastSeen: Int64(0), count: Int64(-1))
        }
        seenStrings[string]?.lastSeen = frameIndex
        seenStrings[string]?.count += 1
    
        var obsoleteStrings = [String]()

        // Go through strings and prune any that have not been seen in while.
        // Also find the (non-pruned) string with the greatest count.
        for (string, obs) in seenStrings {
            // Remove previously seen text after 30 frames (~1s).
            if obs.lastSeen < frameIndex - 30 {
                obsoleteStrings.append(string)
            }
            
            // Find the string with the greatest count.
            let count = obs.count
            if !obsoleteStrings.contains(string) && count > bestCount {
                bestCount = Int64(count)
                bestString = string
            }
        }
        // Remove old strings.
        for string in obsoleteStrings {
            seenStrings.removeValue(forKey: string)
        }
        
        frameIndex += 1
        
        return Float(seenStrings[string]?.count ?? 0) / Float(minRepeat)
    }
    
    
    func logFrameFast(_ string: String) {
        if seenStrings[string] == nil {
            seenStrings[string] = (lastSeen: Int64(0), count: Int64(-1))
        }
        seenStrings[string]?.lastSeen = frameIndex
        seenStrings[string]?.count += 1
    
        var obsoleteStrings = [String]()

        for (string, obs) in seenStrings {

            if obs.lastSeen < frameIndex - 30 {
                obsoleteStrings.append(string)
            }
            let count = obs.count
            if !obsoleteStrings.contains(string) && count > bestCount {
                bestCount = Int64(count)
                bestString = string
            }
        }
        for string in obsoleteStrings {
            seenStrings.removeValue(forKey: string)
        }
        
        frameIndex += 1
    }
    
    func getStableString() -> String? {
        if bestCount >= minRepeat {
            return bestString
        } else {
            return nil
        }
    }
    
    func reset(string: String) {
        seenStrings.removeValue(forKey: string)
        bestCount = 0
        bestString = ""
    }
    
    func reset() {
        seenStrings.removeAll()
        bestCount = 0
        bestString = ""
    }
}

