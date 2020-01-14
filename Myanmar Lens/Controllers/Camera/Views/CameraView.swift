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
    private var isLoading: Bool { return serviceManager.showLoading }
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8 , style: .circular).stroke(Color.white, lineWidth: 1.5).padding(2)
            
            ZStack {
                
                Circle().frame(width: isLoading ? 45 : 55, height: isLoading ? 45 : 55, alignment: .center).onTapGesture {
                    SoundManager.vibrate(vibration: .light)
                    self.serviceManager.didTapActionButton()
                }
                if serviceManager.showLoading {
                    CircularProgressIndicator().frame(width: 65, height: 65, alignment: .center)
                } else {
                    Circle().trim(from: 0, to: 1).stroke(Color.primary, lineWidth: 5).frame(width: 65, height: 65, alignment: .center)
                }
            }.padding()
            HStack(alignment: .bottom, spacing: 13){
                Text(serviceManager.source).underline().onTapGesture {
                    self.serviceManager.didTapSourceLanguage()
                }
                Image(systemName: "arrow.2.squarepath").onTapGesture {
                    self.serviceManager.toggleLanguagePair()
                }.font(.system(size: 25)).padding(.horizontal)
                Text(serviceManager.target).onTapGesture {
                    self.serviceManager.didTapTargetLanguage()
                }
            }.font(.system(size: 18, weight: .medium, design: .monospaced))
            HStack(alignment: .top, spacing: 10){
                Slider(value: $serviceManager.zoom, in: 0...20)
                Spacer()
                Image(systemName: "crop.rotate").onTapGesture {
                    self.serviceManager.didTapFlashLight()
                }
                Image(systemName: "lightbulb.slash.fill").onTapGesture {
                    self.serviceManager.didTapFlashLight()
                }
            }.font(Font.system(size: 23)).padding(7)
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



struct Example4PolygonShape: Shape {
    var sides: Double
    var scale: Double
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(sides, scale) }
        set {
            sides = newValue.first
            scale = newValue.second
        }
    }
    func path(in rect: CGRect) -> Path {
        // hypotenuse
        let h = Double(min(rect.size.width, rect.size.height)) / 2.0 * scale
        // center
        let c = CGPoint(x: rect.size.width / 2.0, y: rect.size.height / 2.0)
        var path = Path()
        let extra: Int = sides != Double(Int(sides)) ? 1 : 0
        var vertex: [CGPoint] = []
        for i in 0..<Int(sides) + extra {
            let angle = (Double(i) * (360.0 / sides)) * (Double.pi / 180)
            // Calculate vertex
            let pt = CGPoint(x: c.x + CGFloat(cos(angle) * h), y: c.y + CGFloat(sin(angle) * h))
            vertex.append(pt)
            if i == 0 {
                path.move(to: pt) // move to first vertex
            } else {
                path.addLine(to: pt) // draw line to next vertex
            }
        }
        path.closeSubpath()
        // Draw vertex-to-vertex lines
        drawVertexLines(path: &path, vertex: vertex, n: 0)
        return path
    }
    func drawVertexLines(path: inout Path, vertex: [CGPoint], n: Int) {
        if (vertex.count - n) < 3 { return }
        for i in (n+2)..<min(n + (vertex.count-1), vertex.count) {
            path.move(to: vertex[n])
            path.addLine(to: vertex[i])
        }
        drawVertexLines(path: &path, vertex: vertex, n: n+1)
    }
}
