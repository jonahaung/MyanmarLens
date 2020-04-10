//
//  LanguageBarView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 10/4/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import SwiftUI
import NaturalLanguage

struct LanguageBarView: View {
    
    @ObservedObject var serviceManager: ServiceManager
    @State private var detectedLanguage = userDefaults.sourceLanguage {
        didSet {
            userDefaults.sourceLanguage = detectedLanguage
        }
    }
    @State private var targetLanguage = userDefaults.targetLanguage {
        didSet {
            userDefaults.targetLanguage = targetLanguage
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Button(action: {
                self.didTapSourceLanguage()
            }) {
                Text(detectedLanguage.localName).underline(color: .primary)
            }
            
            Image(systemName: "chevron.right.2")
                .font(.body)
            
            Button(action: {
                self.didTapTargetLanguage()
            }) {
                Text(targetLanguage.localName)
            }
        }
        .font(.system(size: 18, weight: .medium, design: .monospaced))
        
    }
}

extension LanguageBarView {
    func didTapTargetLanguage() {
        SoundManager.vibrate(vibration: .medium)
        let alert = UIAlertController(title: "Target Language", message: "Pls select one of the following target languages", preferredStyle: .actionSheet)
        let index = Languages.targetLanguages.firstIndex(of: userDefaults.languagePair.target) ?? 1
        
        alert.addPickerView(values: [ Languages.targetLanguages.map{ $0.localName }], initialSelection: PickerViewViewController.Index(0, index)) { (_, _, index, values) in
            let value = values[index.column][index.row]
            let selectedLanguages = Languages.targetLanguages.filter{ $0.localName == value }
            if let language = selectedLanguages.first {
                let newValue = language.rawValue
                let newLanguage = NLLanguage(newValue)
                alert.message = newLanguage.rawValue
                self.targetLanguage = newLanguage
                
            }
        }
        alert.addAction(title: "OK", style: .cancel, handler: nil)
        alert.show()
    }
    
    func didTapSourceLanguage() {
        SoundManager.vibrate(vibration: .medium)
        let alert = UIAlertController(title: "Source Language", message: "Pls select one of the following source languages", preferredStyle: .actionSheet)
        let index = Languages.sourceLanguages.firstIndex(of: userDefaults.languagePair.source) ?? 0
        
        alert.addPickerView(values: [ Languages.sourceLanguages.map{ $0.localName }], initialSelection: PickerViewViewController.Index(0, index)) { (_, _, index, values) in
            let value = values[index.column][index.row]
            let selectedLanguages = Languages.sourceLanguages.filter{ $0.localName == value }
            if let language = selectedLanguages.first {
                let newValue = language.rawValue
                let newLanguage = NLLanguage(newValue)
                alert.message = newLanguage.rawValue
                self.detectedLanguage = newLanguage
                
            }
        }
        
        alert.addAction(title: "OK", style: .cancel, handler: nil)
        alert.show()
    }
}
