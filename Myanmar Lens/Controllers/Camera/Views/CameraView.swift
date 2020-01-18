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
    @EnvironmentObject var userSettings: UserSettings
    @Binding var isPresenting: Bool
    @Binding var showPicker: Bool
   
    var body: some View {
        
        ZStack {
            CameraUIViewRepresentable(serviceManager: serviceManager).environmentObject(userSettings)
            
            CameraControlView(serviceManager: serviceManager, showPicker: $showPicker).environmentObject(userSettings)
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
    @EnvironmentObject var userSettings: UserSettings
    @ObservedObject var serviceManager: ServiceManager
    private var isLoading: Bool { return serviceManager.showLoading }
    @Binding var showPicker: Bool
    var body: some View {
        VStack {
            Spacer() 
            HStack(alignment: .bottom) {
                Spacer()
                Text(userSettings.languagePair.source.localName).underline().onTapGesture {
                    self.serviceManager.didTapSourceLanguage()
                }
                Spacer()
                ZStack {
                    Circle().frame(width: isLoading ? 40 : 50, height: isLoading ? 40 : 50, alignment: .center).onTapGesture {
                        SoundManager.vibrate(vibration: .light)
                        self.serviceManager.didTapActionButton()
                    }
                    if serviceManager.showLoading {
                        CircularProgressIndicator().frame(width: 60, height: 60, alignment: .center)
                    } else {
                        Circle().trim(from: 0, to: 1).stroke(Color.primary, lineWidth: 5).frame(width: 60, height: 60, alignment: .center)
                    }
                }.foregroundColor(.white)
                Spacer()
                Text(userSettings.languagePair.target.localName).onTapGesture {
                    self.showPicker = true
                }
                Spacer()
            }.font(.system(size: 18, weight: .medium, design: .monospaced)).foregroundColor(.yellow).padding(.horizontal)
            
            HStack(spacing: 10){
                
                
                Image(systemName: "repeat").onTapGesture {
                    self.userSettings.toggleLanguagePari()
                    self.serviceManager.languagePair = self.userSettings.languagePair
                }.foregroundColor(.white)
                
                
            }.padding(.horizontal)
            
            HStack {
                Image(systemName: "wand.and.stars").onTapGesture {
                    self.userSettings.isBlackAndWhite.toggle()
                }.foregroundColor(self.userSettings.isBlackAndWhite ? Color.white : Color.yellow)
                Image(systemName: "lightbulb.slash.fill").onTapGesture {
                    self.serviceManager.didTapFlashLight()
                }.padding(.horizontal).foregroundColor(self.serviceManager.touchLightIsOn ? Color.yellow : Color.white)
                Spacer()
                HStack {
                    Slider(value: $serviceManager.zoom, in: 0...20, step: 0.1)
                    Image(systemName: "plus.slash.minus")
                }
            }.padding([.leading, .trailing, .bottom]).font(Font.system(size: 20))
            
            
        }

        
    }
}

struct CameraUIViewRepresentable: UIViewRepresentable {
    
    let serviceManager: ServiceManager
    @EnvironmentObject var userSettings: UserSettings
    
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
