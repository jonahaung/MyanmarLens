//
//  LanguagePickerView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 18/1/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import SwiftUI

struct LanguagePickerView: View {
    
    @EnvironmentObject var userSettings: UserSettings
    
    @Binding var isPresenting: Bool
    @State private var selectedSource = 0
    @State private var selectedTarget = 0
    var body: some View {
        VStack {
           
            Spacer()
            Group {
                HStack {
                    Text(userSettings.languagePair.source.localName)
                    Image(systemName: "arrow.right.circle.fill").padding()
                    Text(userSettings.languagePair.target.localName)
                }.font(.system(.headline, design: .monospaced))
            }
            Group {
                Picker(selection: self.$selectedSource, label: Text("")) {
                    ForEach(0 ..< Languages.sourceLanguages.count) {
                        Text(Languages.sourceLanguages[$0].localName).foregroundColor(Color.white).tag($0)
                    }
                    
                }.pickerStyle(WheelPickerStyle()).padding(.trailing)
            }
            Image(systemName: "chevron.down").frame(width: 60).padding()
            Group {
                Picker(selection: self.$selectedTarget, label: Text("")) {
                ForEach(0 ..< Languages.targetLanguages.count) {
                    Text(Languages.targetLanguages[$0].localName).foregroundColor(Color.white).tag($0)

                    }
                }.pickerStyle(WheelPickerStyle()).padding(.trailing)
            }
            Spacer()
            Group {
                HStack {
                    Text("Done").onTapGesture {
                        self.disappear()
                    }
                }
            }
        }.padding()
        .onAppear(perform: appear)
    }
    
    private func disappear() {
        let languagePair = LanguagePair(source: Languages.sourceLanguages[selectedSource], target: Languages.targetLanguages[selectedTarget])
        userSettings.languagePair = languagePair
        isPresenting = false
    }
    private func appear() {
        if let x = Languages.sourceLanguages.firstIndex(of: userSettings.languagePair.source) {
            self.selectedSource = x
        }
        if let x = Languages.targetLanguages.firstIndex(of: userSettings.languagePair.target) {
            self.selectedTarget = x
        }
    }
}
