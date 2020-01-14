//
//  FlipperView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 12/1/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import SwiftUI

struct RotatingCard: View {
    @State private var flipped = false
    @State private var animate3d = false
    @State private var rotate = false
    @State private var imgIndex = 0
    
    let images: [String] = (1...11).map{ $0.description }
    
    var body: some View {
        let binding = Binding<Bool>(get: { self.flipped }, set: { self.updateBinding($0) })
        
        return VStack {
            Spacer()
            Image(flipped ? "cardBack" : images[imgIndex]).resizable()
                .frame(width: 212, height: 320)
            .cornerRadius(50)
                .modifier(FlipEffect(flipped: binding, angle: animate3d ? 360 : 0, axis: (x: 1, y: 5)))
                .rotationEffect(Angle(degrees: rotate ? 0 : 360))
                .onAppear {
                    withAnimation(Animation.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                        self.animate3d = true
                    }
                    
                    withAnimation(Animation.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                        self.rotate = true
                    }
            }
            Spacer()
        }
    }
    
    func updateBinding(_ value: Bool) {
        // If card was just flipped and at front, change the card
        if flipped != value && !flipped {
            self.imgIndex = self.imgIndex+1 < self.images.count ? self.imgIndex+1 : 0
        }
        
        flipped = value
    }
}

struct FlipEffect: GeometryEffect {
    
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }
    
    @Binding var flipped: Bool
    var angle: Double
    let axis: (x: CGFloat, y: CGFloat)
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        
        // We schedule the change to be done after the view has finished drawing,
        // otherwise, we would receive a runtime error, indicating we are changing
        // the state while the view is being drawn.
        DispatchQueue.main.async {
            self.flipped = self.angle >= 90 && self.angle < 270
        }
        
        let a = CGFloat(Angle(degrees: angle).radians)
        
        var transform3d = CATransform3DIdentity;
        transform3d.m34 = -1/max(size.width, size.height)
        
        transform3d = CATransform3DRotate(transform3d, a, axis.x, axis.y, 0)
        transform3d = CATransform3DTranslate(transform3d, -size.width/2.0, -size.height/2.0, 0)
        
        let affineTransform = ProjectionTransform(CGAffineTransform(translationX: size.width/2.0, y: size.height / 2.0))
        
        return ProjectionTransform(transform3d).concatenating(affineTransform)
    }
}
