//
//  ContentView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 20/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import SwiftUI
import UIKit
struct ContentView: View {
    
    
    var body: some View {
        ZStack {
            Image("background").resizable().scaledToFill().brightness(0.1)
            VStack(alignment: .center) {
                Spacer()
                Text("Myanmar Lens")
                Spacer()
                Button(action: {
                    self.start()
                }) {
                    Image(systemName: "camera.fill").padding().background(Color.secondary).cornerRadius(8)
                }
                Spacer()
            }.font(.largeTitle)
        }
        
    }
    
    private func start() {
        SoundManager.playSound(tone: .Tock)
        let vc = MyanmarLensController()
        vc.modalPresentationStyle = .overFullScreen
        UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
