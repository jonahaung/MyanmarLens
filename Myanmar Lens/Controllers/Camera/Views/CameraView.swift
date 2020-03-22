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
            
            VStack {
                Group {
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
                if serviceManager.displayingResults {
                    Group {
                        
                        if serviceManager.showLoading {
                            CircularProgressIndicator()
                                .frame(width: 40, height: 40)
                        }
                        
                        HStack {
                            Button(action: {
                                SoundManager.vibrate(vibration: .light)
                                self.serviceManager.didTapSkew()
                            }) {
                                Image(systemName: "skew")
                            }
                            Spacer()
                            Button(action: {
                                self.serviceManager.didTapSkew()
                            }) {
                                Image(systemName: "wand.and.stars")
                            }
                            Spacer()
                            Button(action: {
                                SoundManager.vibrate(vibration: .medium)
                                self.serviceManager.didTapShareButton()
                                
                            }) {
                                Image(systemName: "arrowshape.turn.up.right")
                            }
                            Spacer()
                            Button(action: {
                                self.serviceManager.saveAsImage()
                            }) {
                                Image(systemName: "arrow.down.to.line")
                            }
                            Spacer()
                            Button(action: {
                                self.serviceManager.reset()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                            }
                                
                            .accentColor(.red)
                        }
                        
                    }
                    .font(Font.system(size: 28, weight: .light))
                    .accentColor(.blue)
                    .padding()
                    
                }else {
                    CameraControlView(serviceManager: serviceManager).environmentObject(serviceManager)
                    
                }
            }
            
        }
            
        .accentColor(Color(.orange))
        .onAppear {
            self.serviceManager.configure()
        }
    }
}

struct CameraControlView: View {
    
    @ObservedObject var serviceManager: ServiceManager
    private var isLoading: Bool { return serviceManager.showLoading }
    
    var body: some View {
        VStack {
            
            
            Group {
                
                ZStack {
                    
                    HStack(alignment: .bottom) {
                        Button(action: {
                            SoundManager.vibrate(vibration: .light)
                            withAnimation {
                            }
                            self.serviceManager.isAutoScan.toggle()
                        }) {
                            VStack{
                                Text(self.serviceManager.isAutoScan ? "Auto" : "Manual")
                            }
                        }
                        
                        Spacer()
                    }
                    .font(.callout)
                    .accentColor(.primary)
                    
                    Button(action: {
                        self.serviceManager.didTapActionButton()
                    }) {
                        
                        
                        ZStack {
                            Image(systemName: "circle.fill")
                                .resizable()
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 55)
                        }
                    }
                    .frame(width: 63, height: 63)
                    .padding()
                }
                .padding(.horizontal)
                
            }.zIndex(10)
            
            Group {
                
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
                                .padding().background(Circle().fill(Color(.secondarySystemFill)))
                        }
                        
                        // Zoom
                        
                        Button(action: {
                            withAnimation(Animation.interactiveSpring()) {
                                self.serviceManager.selectedButton = .zoom
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
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
