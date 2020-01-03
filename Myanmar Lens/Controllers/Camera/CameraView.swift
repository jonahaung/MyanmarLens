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
    @State private var isToggle : Bool = userDefaults.isRepeat
    @State var mapChoioce = 0
    var settings = ["Tentative", "Vertifiable", "Stable"]
    
    var body: some View {
        ZStack {
            CameraUIViewRepresentable(serviceManager: serviceManager)
            if !serviceManager.isStopped {
                 CircularProgressIndicator()
                
            }
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    Image(uiImage: serviceManager.image).resizable().frame(width: 100, height: 150, alignment: .leading)
                }
                
                HStack{
                    
                    Button(action: {
                        self.serviceManager.didTapActionButton()
                    }) {
                        Image(systemName: "largecircle.fill.circle").accentColor(.blue)
                    }.font(.system(size: 70, weight: .thin))
                }
                
                HStack{
                    Button(action: {
                        self.serviceManager.didTapFlashLight()
                    }) {
                        Image(systemName: "lightbulb.slash.fill")
                    }
                    Spacer()
                    Stepper(value: $serviceManager.zoom, in: 0...20, label: {Text("")})
                    
                }.padding(.horizontal).font(.headline)
                
                HStack {
                    Picker("Accuracy", selection: $mapChoioce) {
                        ForEach(0 ..< settings.count) { index in
                            Text(self.settings[index])
                                .tag(index)
                        }
                        
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    Toggle(isOn: $isToggle){
                        Text(self.isToggle ? "Repeat" : "Non Repeat").font(.footnote)
                    }
                    
                }.padding()
                
                }
            .navigationBarTitle(serviceManager.source)
            .navigationBarItems(trailing:
                HStack{
                    Text(serviceManager.source)
                    Button(action: {
                        self.serviceManager.toggleLanguagePair()
                    }) {
                        Image(systemName: "chevron.right.2")
                    }
                    
                    Text(serviceManager.target)
            })
        }
        .onAppear {
            self.serviceManager.configure()
            
        }
        .onDisappear { self.serviceManager.stop() }
    }

}


struct CircularProgressIndicator: View {
    @State var spinCircle = false

    var body: some View {
        VStack {
            Circle()
            .trim(from: 0.5, to: 1)
            .stroke(lineWidth: 2)
            .frame(width: 50)
            .rotationEffect(.degrees(spinCircle ? 0 : -360), anchor: .center)
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
            .onAppear {
                self.spinCircle = true
            }
        }
        
    }
    
}

struct CircularProgressIndicator_Previews: PreviewProvider {
    static var previews: some View {
        CircularProgressIndicator()
    }
}
