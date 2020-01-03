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
    @State private var isCamera = !userDefaults.currentBoolObjectState(for: userDefaults.hasDoneEULA)
    
    var body: some View {
        VStack {
            HStack{
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "scribble").padding()
                }
                Spacer()
                
                Button(action: {
                    userDefaults.toggleSourceLanguage()
                    self.sourceLanguage = userDefaults.languagePair.source.localName
                }) {
                    Text(self.sourceLanguage)
                }
            }.font(.largeTitle)
            Spacer()
            
            HStack{
//                NavigationLink(destination: HistoryView().environment(\.managedObjectContext, context), isActive: $isCamera) {
//                    Image(systemName: "camera.fill").padding()
//                }.font(.largeTitle)
                NavigationLink(destination: CameraView(), isActive: $isCamera) {
                    Image(systemName: "camera.fill").padding()
                }.font(.largeTitle)
                
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
            self.sourceLanguage = userDefaults.languagePair.source.localName
        }
    }
}


