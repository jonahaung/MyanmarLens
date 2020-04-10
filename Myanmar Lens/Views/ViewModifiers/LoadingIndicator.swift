//
//  LoadingIndicator.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 12/1/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import SwiftUI
import UIKit
struct LoadingIndicator: View {
    
    @Binding var value: CGFloat
    
    var body: some View {
        Circle()
            .trim(from: 0, to: value)
            .stroke(Color.white, lineWidth: 3)
            
            .rotationEffect(Angle(degrees:-90))
            .animation(Animation.linear(duration: 0.3))
    }
    
    func getPercentage(_ value:CGFloat) -> String {
        let intValue = Int(ceil(value * 100))
        return "\(intValue) %"
    }
}
struct CircularProgressIndicator: View {
    
    @State var spinCircle = false
    
    var body: some View {
        Circle()
            
            .trim(from: 0.7, to: 1)
            .stroke(Color.white, lineWidth: 3)
            .rotationEffect(.degrees(spinCircle ? 0 : -360), anchor: .center)
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
            .onAppear {
                self.spinCircle = true
        }
        .onDisappear {
            self.spinCircle = false
        }
    }
}
