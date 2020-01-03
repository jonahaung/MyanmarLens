//
//  CameraController+Language.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 8/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit
import NaturalLanguage

extension CameraController {
    
    @objc func didTapTargetLanguage(_ sender: Any) {
        SoundManager.vibrate(vibration: .medium)
        let alert = UIAlertController(title: "Target Language", message: "Pls select one of the following target languages", preferredStyle: .actionSheet)
        let index = Languages.targetLanguages.firstIndex(of: userDefaults.languagePair.target) ?? 1
        var selected: String?
    
        let okAction = UIAlertAction(title: "Update Language", style: .default) { _ in
            if let selected = selected {
                let selectedLanguages = Languages.targetLanguages.filter{ $0.localName == selected }
                if let language = selectedLanguages.first {
                    let newValue = language.rawValue
                    let newlanguagePair = LanguagePair(source: userDefaults.languagePair.source, target: NLLanguage(newValue))
                    userDefaults.languagePair = newlanguagePair
                    self.delegate?.languagePair = newlanguagePair
                }
            }
        }
        okAction.isEnabled = false
        alert.addPickerView(values: [ Languages.targetLanguages.map{ $0.localName }], initialSelection: PickerViewViewController.Index(0, index)) { (_, _, index, values) in
            let value = values[index.column][index.row]
            let isValid = value != userDefaults.languagePair.source.localName
            okAction.isEnabled = isValid
            if isValid {
                alert.title = value
                               alert.message = "Press Update to select this language"
                               selected = value
            } else {
                SoundManager.vibrate(vibration: .error)
                alert.title = "Not Allowed!"
                alert.message = "Source Language and Target Language should not be the same..."
                selected = nil
               
            }
             
        }
        alert.addAction(okAction)
        alert.addCancelAction()
        alert.show()
    }
    
    @objc func didTapSourceLanguage(_ sender: Any) {
            SoundManager.vibrate(vibration: .medium)
            let alert = UIAlertController(title: "Source Language", message: "Pls select one of the following source languages", preferredStyle: .actionSheet)
        let index = Languages.sourceLanguages.firstIndex(of: userDefaults.languagePair.source) ?? 0
            var selected: String?
        
            let okAction = UIAlertAction(title: "Update Language", style: .default) { _ in
                if let selected = selected {
                    let selectedLanguages = Languages.sourceLanguages.filter{ $0.localName == selected }
                    if let language = selectedLanguages.first {
                        let newValue = language.rawValue
                        let newlanguagePair = LanguagePair(source: NLLanguage(newValue), target: userDefaults.languagePair.target)
                        userDefaults.languagePair = newlanguagePair
                        self.delegate?.languagePair = userDefaults.languagePair
                    }
                }
            }
            okAction.isEnabled = false
            alert.addPickerView(values: [ Languages.sourceLanguages.map{ $0.localName }], initialSelection: PickerViewViewController.Index(0, index)) { (_, _, index, values) in
                let value = values[index.column][index.row]
                let isValid = value != userDefaults.languagePair.target.localName
                okAction.isEnabled = isValid
                if isValid {
                    alert.title = value
                    alert.message = "Press Update to select this language"
                    selected = value
                } else {
                    SoundManager.vibrate(vibration: .error)
                    alert.title = "Not Allowed!"
                    alert.message = "Source Language and Target Language should not be the same..."
                    selected = nil
                }

            }
            alert.addAction(okAction)
            alert.addCancelAction()
            alert.show()
    }
}
