//
//  ContentView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 20/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import SwiftUI
import CoreData

struct MainView: View {
    
    @Environment(\.managedObjectContext) var context: NSManagedObjectContext
    @State private var notDoneEULA = !userDefaults.currentBoolObjectState(for: userDefaults.hasDoneEULA)
    @State private var sourceLanguage: String = "Source Language"
    private var isMyanmar: Bool { return sourceLanguage == "Burmese" }
    var body: some View {
        
        VStack(alignment: .center) {
            HStack{
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "scribble").padding()
                }
                Spacer()
                
                Button(action: {
                    userDefaults.toggleSourceLanguage()
                    self.sourceLanguage = userDefaults.sourceLanguage.description
                }) {
                    Text(self.sourceLanguage)
                }
            }.font(.largeTitle)
            Spacer()
            HStack{
                
                NavigationLink(destination: HistoryView().environment(\.managedObjectContext, context)) {
                    Image(systemName: "eyeglasses").padding().padding()
                }
                
                Spacer()
                
                Button(action: {
                    SoundManager.vibrate(vibration: .light)
                    let vc = CameraViewController()
                    Navigator.push(vc)
                }) {
                    Image(systemName: "camera.fill").padding()
                }.font(.largeTitle).padding()
                
                Spacer()
                
                NavigationLink(destination: FavouritesView().environment(\.managedObjectContext, context)) {
                    Image(systemName: "heart").padding()
                }
            }.font(.title)
            
        }
        .background(Image("background").resizable().scaledToFill())
        .navigationBarTitle("Myanmar Lens")
        .sheet(isPresented: $notDoneEULA, onDismiss: {
            self.notDoneEULA = !userDefaults.currentBoolObjectState(for: userDefaults.hasDoneEULA)
        }, content: {
            TermsAndConditions(notDoneEULA: self.$notDoneEULA)
        })
        .onAppear {
                self.sourceLanguage = userDefaults.sourceLanguage.description
        }
    }
}


