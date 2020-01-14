//
//  SwiftUIView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 13/1/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import SwiftUI

struct FlowerView: View {
    @State private var animate = false
    
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    
    var body: some View {
        ZStack {
            ForEach(0..<7) { i in
                FlowerColor(petals: self.getPetals(i), length: self.getLength(i), color: self.colors[i])
            }
            .rotationEffect(Angle(degrees: animate ? 360 : 0))
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 25.0).repeatForever()) {
                    self.animate = true
                }
            }
        }
    }
    
    func getLength(_ i: Int) -> Double {
        return 1 - (Double(i) * 1 / 7)
    }
    
    func getPetals(_ i: Int) -> Int {
        return i * 2 + 15
    }
}
struct FlowerColor: View {
    let petals: Int
    let length: Double
    let color: Color
    
    @State private var animate = false
    
    var body: some View {
        let petalWidth1 = Angle(degrees: 2)
        let petalWidth2 = Angle(degrees: 360 / Double(self.petals)) * 2
        
        return GeometryReader { proxy in
            
            ForEach(0..<self.petals) { i in
                PetalShape(angle: Angle(degrees: Double(i) * 360 / Double(self.petals)), arc: self.animate ? petalWidth1 : petalWidth2, length: self.animate ? self.length : self.length * 0.9)
                    .fill(RadialGradient(gradient: Gradient(colors: [self.color.opacity(0.2), self.color]), center: UnitPoint(x: 0.5, y: 0.5), startRadius: 0.1 * min(proxy.size.width, proxy.size.height) / 2.0, endRadius: min(proxy.size.width, proxy.size.height) / 2.0))
            }
            
        }.onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever()) {
                self.animate = true
            }
        }
    }
}

struct PetalShape: Shape {
    let angle: Angle
    var arc: Angle
    var length: Double
    
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(arc.degrees, length) }
        set {
            arc = Angle(degrees: newValue.first)
            length = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let hypotenuse = Double(min(rect.width, rect.height)) / 2.0 * length
        
        let sep = arc / 2
        
        let to = CGPoint(x: CGFloat(cos(angle.radians) * Double(hypotenuse)) + center.x,
                         y: CGFloat(sin(angle.radians) * Double(hypotenuse)) + center.y)
        
        let ctrl1 = CGPoint(x: CGFloat(cos((angle + sep).radians) * Double(hypotenuse)) + center.x,
                            y: CGFloat(sin((angle + sep).radians) * Double(hypotenuse)) + center.y)
        
        let ctrl2 = CGPoint(x: CGFloat(cos((angle - sep).radians) * Double(hypotenuse)) + center.x,
                            y: CGFloat(sin((angle - sep).radians) * Double(hypotenuse)) + center.y)
        
        
        var path = Path()
        
        path.move(to: center)
        path.addQuadCurve(to: to, control: ctrl1)
        path.addQuadCurve(to: center, control: ctrl2)
        
        return path
    }
    
}
