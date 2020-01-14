//
//  WeaveTextModifier.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 12/1/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import SwiftUI

struct WaveTextModifier: AnimatableModifier {
    let text: String
    let waveWidth: Int
    var pct: Double
    var size: CGFloat
    
    var animatableData: Double {
        get { pct }
        set { pct = newValue }
    }
    
    func body(content: Content) -> some View {
        
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.0) { (n, ch) in
                Text(String(ch))
                    .font(Font.custom("Menlo", size: self.size).bold())
                    .scaleEffect(self.effect(self.pct, n, self.text.count, Double(self.waveWidth)))
            }
        }
    }
    
    func effect(_ pct: Double, _ n: Int, _ total: Int, _ waveWidth: Double) -> CGFloat {
        let n = Double(n)
        let total = Double(total)
        
        return CGFloat(1 + valueInCurve(pct: pct, total: total, x: n/total, waveWidth: waveWidth))
    }
    
    func valueInCurve(pct: Double, total: Double, x: Double, waveWidth: Double) -> Double {
        let chunk = waveWidth / total
        let m = 1 / chunk
        let offset = (chunk - (1 / total)) * pct
        let lowerLimit = (pct - chunk) + offset
        let upperLimit = (pct) + offset
        guard x >= lowerLimit && x < upperLimit else { return 0 }
        
        let angle = ((x - pct - offset) * m)*360-90
        
        return (sin(angle.rad) + 1) / 2
    }
}

extension Double {
    var rad: Double { return self * .pi / 180 }
    var deg: Double { return self * 180 / .pi }
}
