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
    
    @State var showPicker = false
    
    var body: some View {
        ZStack {
            CameraUIViewRepresentable(serviceManager: serviceManager).environmentObject(userSettings)
            CameraControlView(serviceManager: serviceManager).environmentObject(userSettings)
            .onAppear {
                self.serviceManager.configure()
            }
            .onDisappear {
                self.serviceManager.stop()
            }
        }
    }
}

struct CameraControlView: View {
    
    @ObservedObject var serviceManager: ServiceManager
    private var isLoading: Bool { return serviceManager.showLoading }
    var body: some View {
        VStack {
            HStack(spacing: 10){
                Spacer()
                Text(serviceManager.languagePair.source.localName).underline().onTapGesture {
                    self.serviceManager.didTapSourceLanguage()
                }
                Image(systemName: "repeat").onTapGesture {
                    self.serviceManager.toggleLanguagePair()
                }
                
                Text(serviceManager.languagePair.target.localName).underline().onTapGesture {
                    self.serviceManager.didTapTargetLanguage()
                }
                Spacer()
            }.padding().font(.system(size: 20, weight: .semibold, design: .monospaced)).foregroundColor(Color.yellow)
            
            Spacer()
            
            HStack(alignment: .top) {
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
            
            }

            HStack {
                Image(systemName: "paintbrush.fill").onTapGesture {
                    self.serviceManager.isBlackAndWhite.toggle()
                }.foregroundColor(self.serviceManager.isBlackAndWhite ? Color.white : Color.yellow)
                Image(systemName: "lightbulb.slash.fill").onTapGesture {
                    self.serviceManager.didTapFlashLight()
                }.padding(.horizontal).foregroundColor(self.serviceManager.touchLightIsOn ? Color.yellow : Color.white)
                Spacer()
                Slider(value: $serviceManager.zoom, in: 0...20, step: 0.1)
            }.padding().font(Font.system(size: 20))
            
            
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
