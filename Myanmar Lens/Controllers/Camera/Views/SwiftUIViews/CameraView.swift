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
            // Overlay
            OverlayViewR(serviceManager: serviceManager)
            
            VStack {
                // Language Bar
                LanguageBarView(serviceManager: serviceManager)
                
                Spacer()
                
                if serviceManager.displayingResults {
                    // Results
                    ResultsView(serviceManager: serviceManager)
                }else {
                    // Controls
                    ControlsView(serviceManager: serviceManager)
                }
            }
            .padding()
            
        }
        .accentColor(Color(.orange))
        .onAppear {
            self.serviceManager.configure()
        }
    }
}

// Overlay View
struct OverlayViewR: UIViewRepresentable {
    
    @State var serviceManager: ServiceManager
    
    func makeUIView(context: Context) -> OverlayView {
        return serviceManager.overlayView
    }
    
    func updateUIView(_ uiView: OverlayView, context: Context) {
        
    }
}
