//
//  CameraControlsView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 8/4/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import SwiftUI

struct ControlsView: View {
    
    @ObservedObject var serviceManager: ServiceManager
    private var isLoading: Bool { return serviceManager.showLoading }
    @State private var textTheme = userDefaults.textTheme
    @State private var showZoomSlider = false
    @State private var isTracking = false {
        didSet {
            serviceManager.isTracking = isTracking
        }
    }
    
    var body: some View {
        VStack {
            if isTracking {
                Circle()
                    .fill(Color.pink)
                    .frame(width: 20, height: 50)
            
            }
            ZStack {
                Image(systemName: "circle.fill")
                .resizable()
                .foregroundColor(.orange)
                Image(systemName: "circle.fill")
                    .resizable()
                    .frame(width: isTracking ? 90 : 55, height: isTracking ? 90 : 55)
                    .onTapGesture {
                        self.isTracking = false
                        self.serviceManager.didTapActionButton()
                    }
                    .onLongPressGesture(minimumDuration: 60, maximumDistance: 60, pressing: { isPress in
                        withAnimation(.interactiveSpring()) {
                            self.isTracking = isPress
                        }
                    }) {
                        print(222)
                    }
            }
            .frame(width: 63, height: 63)
            
            
            Section {
                
                VStack {
                    if serviceManager.isStopped {
                        VStack {
                            Text("Paused!")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                            Text("Tap the camera screen to resume")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    if showZoomSlider {
                        Slider(value: $serviceManager.zoom, in: 0...20, minimumValueLabel: Text(""), maximumValueLabel: Text("\((serviceManager.zoom * 5).int)")) { EmptyView() }
                    }
                    
                    HStack(spacing: 0) {
                        // Text Color
                        Button(action: {
                            self.toggleTextTheme()
                        }) {
                            Image(systemName: textTheme.iconName)
                                .padding()
                                .background(Circle()
                                    .fill(Color.init(.systemFill)))
                        }
                        
                        
                        // Flash
                        Button(action: {
                            self.toggleFlash()
                        }) {
                            Image(systemName: "bolt.fill")
                                .padding()
                                .background(Circle()
                                .fill(Color(.secondarySystemFill)))
                        }
                        
                        // Zoom
                        
                        Button(action: {
                            self.toggleZoom()
                        }) {
                            Image(systemName: "magnifyingglass")
                                .padding().background(Circle().fill(Color(.secondarySystemFill)))
                        }
                        
                        Spacer()
                        
                        VStack {
                            
                            Button(action: {
                                self.serviceManager.didTappedFPS()
                            }) {
                                Text(serviceManager.fps.description).font(.title) + Text(" FPS").font(.caption)
                            }
                            .accentColor(.primary)
                            Button(action: {
                                self.serviceManager.videoQuality = self.serviceManager.videoQuality.opposite
                            }) {
                                Text(serviceManager.videoQuality.label)
                            }
                            
                        }
                        .font(.caption).padding(.horizontal)
                    }
                    .font(Font.system(size: 25, weight: .light))
                }
            }
        }
    }
    
    // Text Theme
    private func toggleTextTheme() {
        SoundManager.vibrate(vibration: .light)
        withAnimation {
            textTheme = textTheme == .Adaptive ? .BlackAndWhite : .Adaptive
            userDefaults.textTheme = textTheme
        }
    }
    // Zoom
    private func toggleZoom() {
        SoundManager.vibrate(vibration: .light)
        withAnimation(.interactiveSpring()) {
            showZoomSlider.toggle()
        }
    }
    // Flash
    private func toggleFlash() {
        SoundManager.vibrate(vibration: .light)
        CaptureSession.current.toggleFlash()
    }
}
