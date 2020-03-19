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
    
    var body: some View {
        ZStack {
            CameraUIViewRepresentable(serviceManager: serviceManager)
            CameraControlView(serviceManager: serviceManager).environmentObject(serviceManager)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
        }
        .accentColor(Color(.orange))
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
            
            Section {
                HStack(spacing: 10) {
                    Button(action: {
                        self.serviceManager.didTapSourceLanguage()
                    }) {
                        Text(serviceManager.detectedLanguage.localName).underline(color: .primary)
                    }
                    
                    Image(systemName: "chevron.right.2")
                    .font(.body)
                    
                    Button(action: {
                        self.serviceManager.didTapTargetLanguage()
                    }) {
                        Text(serviceManager.targetLanguage.localName)
                    }
                }.font(.system(size: 18, weight: .medium, design: .monospaced)).padding(.top)
            }.zIndex(10)
            
            
            Spacer()
            
            Section {
                
                ZStack {
                    
                    Button(action: {
                       
                        self.serviceManager.didTapActionButton()
                    }) {
                        
                        
                        ZStack {
                            Image(systemName: "circle.fill")
                                .resizable()
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 55)
                            if serviceManager.showLoading {
                                CircularProgressIndicator()
                                .frame(width: 60)
                            }
                            
                        }
                    }
                    .frame(width: 63, height: 63)
                    .padding()
                }
                
            }.zIndex(10)
            
            Section {
                
                VStack {
                   
                   if serviceManager.selectedButton == .zoom {
                                          
                      Slider(value: $serviceManager.zoom, in: 0...20, minimumValueLabel: Text(""), maximumValueLabel: Text("\((serviceManager.zoom * 5).int)")) { EmptyView() }
                        
                     }else if serviceManager.selectedButton == .textColor {
                         Picker("Options", selection: $serviceManager.choice) {
                             ForEach(0 ..< TextTheme.allCases.count) {
                                 Text(TextTheme.allCases[$0].label).tag($0)
                             }
                         }.pickerStyle(SegmentedPickerStyle())
                     }
                    HStack(spacing: 0) {
                        // Text Color
                        Button(action: {
                            withAnimation(Animation.interactiveSpring()) {
                                self.serviceManager.selectedButton = .textColor
                            }
                        }) {
                            Image(systemName: self.serviceManager.textTheme.iconName)
                                .padding().background(Circle().fill(Color.init(.systemFill)))
                        }
                        
                        
                        
                        // Flash
                        Button(action: {
                            self.serviceManager.toggleFlash()
                        }) {
                            Image(systemName: serviceManager.flashState.iconName)
//                            .accentColor(serviceManager.selectedButton == .flash ? .primary : .orange)
                            .padding().background(Circle().fill(Color(.secondarySystemFill)))
                        }
                        
                        // Zoom
                        
                        Button(action: {
                            withAnimation(Animation.interactiveSpring()) {
                                 self.serviceManager.selectedButton = .zoom
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
//                            .accentColor(serviceManager.selectedButton == .zoom ? .primary : .orange)
                            .padding().background(Circle().fill(Color(.secondarySystemFill)))
                        }
                        
                        Spacer()
            
                        VStack {
                            
                            Text(serviceManager.fps.description).font(.title) + Text(" FPS").font(.caption)
                            Button(action: {
                                self.serviceManager.videoQuality = self.serviceManager.videoQuality.opposite
                            }) {
                                Text(serviceManager.videoQuality.label)
                            }
                            
                        }.font(.caption).padding(.horizontal)
                    }
                    .font(Font.system(size: 25, weight: .light))
               }
                
                .padding(10)
                 
            }
        }
    }
}

struct CameraUIViewRepresentable: UIViewRepresentable {
    
    @State var serviceManager: ServiceManager
    
    func makeUIView(context: Context) -> OverlayView {
        return serviceManager.overlayView
    }
    
    func updateUIView(_ uiView: OverlayView, context: Context) {
        
    }
}
