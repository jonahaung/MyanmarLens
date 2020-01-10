//
//  CameraView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 28/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import SwiftUI

struct CameraView: View {
    
    @ObservedObject var serviceManager = ServiceManager()
   
    var body: some View {
        ZStack {
            
            CameraUIViewRepresentable(serviceManager: serviceManager)
            
            
            CameraControlView(serviceManager: serviceManager)
            
            .navigationBarTitle(serviceManager.source)
        }
        .onAppear {
            self.serviceManager.configure()
        }
        .onDisappear {
            self.serviceManager.stop()
        }
    }

}

struct CameraControlView: View {
    
    @ObservedObject var serviceManager: ServiceManager
    
    var body: some View {
        VStack {
            
            Spacer()
            VStack {
                HStack {
                    Text(serviceManager.source).onTapGesture {
                        self.serviceManager.didTapSourceLanguage()
                    }
                    Spacer()
                    ZStack {
                        if !self.serviceManager.isStopped {
                            CircularProgressIndicator()
                        }
                        Circle().fill(Color.white).frame(width: 55, height: 55, alignment: .center).onTapGesture {
                            self.serviceManager.didTapActionButton()
                        }
                        
                    }
                    Spacer()
                    Text(serviceManager.target).onTapGesture {
                        self.serviceManager.didTapTargetLanguage()
                    }
                }.font(.system(size: 18, weight: .medium, design: .monospaced))
                
                Toggle(isOn: $serviceManager.isRepeat) {
                    HStack(spacing: 15){
                        Image(systemName: "lightbulb.slash.fill").onTapGesture {
                            self.serviceManager.didTapFlashLight()
                        }
                        Slider(value: $serviceManager.zoom, in: 0...20)
                    }
                    
                }
            }.padding()
        }
        
    }
}
struct CircularProgressIndicator: View {
    
    @State var spinCircle = false
    
    var body: some View {
        Circle()
            .trim(from: 0.5, to: 1)
            .stroke(lineWidth: 3)
            .fill(Color.blue)
            .frame(width: 63, height: 63
                , alignment: .center)
            .rotationEffect(.degrees(spinCircle ? 0 : -360), anchor: .center)
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
            
            .onAppear {
                self.spinCircle = true
        }
        
    }
    
}


struct CameraUIViewRepresentable: UIViewRepresentable {
    
    let serviceManager: ServiceManager

    func makeUIView(context: Context) -> OverlayView {
        return serviceManager.overlayView
    }

    func updateUIView(_ uiView: OverlayView, context: Context) {

    }
}
