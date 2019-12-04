//
//  SettingsView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 25/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    
    private let settings = Setting.all
    @State var aboutDeveloper = false
    
    var body: some View {
        VStack{
            Text("Myanmar Lens").font(.largeTitle).padding(.vertical, 20)
            List(settings, id: \.self) { setting in
                SettingCell(setting: setting).onTapGesture {
                    self.tapped(setting: setting)
                }
            }
        }.padding()
        
        .foregroundColor(.secondary)
        .background(Image("background").resizable().scaledToFill())
        .navigationBarTitle("Settings")
        .sheet(isPresented: $aboutDeveloper) { AboutDeveloper() }
    }
}

extension SettingsView {
    
    private func tapped(setting: Setting) {
        switch setting {
        case .DeviceSettings:
            AppUtilities.gotoDeviceSettings()
        case .ResetSettings:
            resetSettings()
        case .AboutDeveloper:
            aboutDeveloper = true
        case .ShareApp:
            AppUtilities.shareApp()
        case .PrivacyPolicy:
            AppUtilities.gotoPrivacyPolicy()
        case .ContactUs:
            AppUtilities.shared.gotoContactUs()
        }
    }
    
    private func resetSettings() {
        let clearHistory = {
            self.clearAllHistory()
        }
        let resetLanguage = {
            self.resetLanguage()
        }
        AlertPresenter.presentActionSheet(actions: [("Clear All History", clearHistory), ("Reset Language", resetLanguage)])
    }
    
    private func clearAllHistory() {
        let action = {
            if PersistanceManager.shared.viewContext.deleteAllData(entityName: TranslatePair.description()) {
                AlertPresenter.show(title: "Succefully deleted all records", message: nil)
            }
        }
        AlertPresenter.presentActionSheet(title: "This action will delete all records permanently. Continue?", actions: [("Yes, Continue", action)])
    }
    
    private func resetLanguage() {
        let action = {
            userDefaults.resetToDefaults()
            AlertPresenter.show(title: "Language is set to English")
        }
        AlertPresenter.presentActionSheet(title: "Reset Language to English?", actions: [("Yes, Continue", action)])
    }
}
