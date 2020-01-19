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
    
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.managedObjectContext) var context: NSManagedObjectContext
    @State private var notDoneEULA = !userDefaults.currentBoolObjectState(for: userDefaults.hasDoneEULA)
    @State private var showCamera: Bool = false

    var body: some View {
        VStack {
            HStack{
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "scribble").padding()
                }
                Spacer()
                Button(action: {
                    self.userSettings.toggleLanguagePari()
                }) {
                    Text(self.userSettings.languagePair.source.localName)
                }
            }.font(.largeTitle)
            Spacer()
            HStack{
                NavigationLink(destination: HistoryView().environment(\.managedObjectContext, context)) {
                    Image(systemName: "eyeglasses")
                }
                Spacer()
                Image(systemName: "camera.fill").onTapGesture {
                    SoundManager.vibrate(vibration: .medium)
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
            print(self.showCamera)
//            self.showCamera = false
        }, content: {
            CameraView().environmentObject(self.userSettings)
        })
            
    }
}
