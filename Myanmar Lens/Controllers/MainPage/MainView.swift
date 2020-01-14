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
    @State private var sourceLanguage: String = userDefaults.languagePair.source.localName
    @State private var showCamera: Bool = false
    private var isMyanmar: Bool { return sourceLanguage == "Burmese" }
    
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
                NavigationLink(destination: HistoryView().environment(\.managedObjectContext, context)) {
                    Image(systemName: "eyeglasses")
                }
                Spacer()
                Image(systemName: "camera.fill").onTapGesture {
                    self.showCamera = true
                }.font(.largeTitle).padding()
                Spacer()
                
                NavigationLink(destination: FavouritesView().environment(\.managedObjectContext, context)) {
                    Image(systemName: "heart")
                }
            }.padding().font(.title)
            
        }
            
        .background(Image("1").resizable().scaledToFill())
        .navigationBarTitle("Myanmar Lens")
        .sheet(isPresented: $notDoneEULA, onDismiss: {
            self.notDoneEULA = !userDefaults.currentBoolObjectState(for: userDefaults.hasDoneEULA)
        }, content: {
            TermsAndConditions(notDoneEULA: self.$notDoneEULA)
        })
            .sheet(isPresented: $showCamera, onDismiss: {
                self.showCamera = false
            }, content: {
                CameraView()
            })
    }
}
