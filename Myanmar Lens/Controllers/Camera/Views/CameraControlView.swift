//
//  CameraControlView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 4/1/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import SwiftUI

struct CameraControlView: View {
    
    @ObservedObject var serviceManager: ServiceManager
    
    var repeatImageName: String {
        return serviceManager.isRepeat ? "repeat" : "repeat.1"
    }
    
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                if !self.serviceManager.isStopped {
                    CircularProgressIndicator()
                }  
                Circle().frame(width: 60, height: 60, alignment: .center).onTapGesture {
                    self.serviceManager.didTapActionButton()
                }
                
            }
            Slider(value: $serviceManager.zoom, in: 0...20)
            HStack(spacing: 15) {
                Image(systemName: "lightbulb.slash.fill").onTapGesture {
                    self.serviceManager.didTapFlashLight()
                }
                Spacer()
                Toggle(isOn: $serviceManager.isRepeat) {
                    Text("Auto Repeat").font(.footnote)
                }
            }
            }.foregroundColor(.white).padding()
        
    }
}
struct CircularProgressIndicator: View {
    
    @State var spinCircle = false
    
    var body: some View {
        Circle()
            .trim(from: 0.5, to: 1)
            .stroke(lineWidth: 1.5)
            .frame(width: 63, height: 63
                , alignment: .center)
            .rotationEffect(.degrees(spinCircle ? 0 : -360), anchor: .center)
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
            .onAppear {
                self.spinCircle = true
        }
        
    }
    
}
