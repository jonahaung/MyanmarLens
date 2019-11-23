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
        NavigationView{
            VStack(alignment: .leading) {
                
                Button(action: {
                    self.start()
                }) {
                    HStack{
                        Image(systemName: "camera.fill")
                         Text("Camara")
                    }
                }
                Button(action: {
                    self.start()
                }) {
                    HStack{
                        Image(systemName: "photo")
                        Text("Photo Library")
                    }
                }
                
            }
            .navigationBarTitle("Myanmar Lens")
        }.font(.title)
    }
    
    private func start() {
        let vc = MyanmarLensController()
        vc.modalPresentationStyle = .fullScreen
        UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
