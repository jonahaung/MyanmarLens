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
           
            
            CameraControlView(serviceManager: serviceManager).foregroundColor(.white)
            
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
