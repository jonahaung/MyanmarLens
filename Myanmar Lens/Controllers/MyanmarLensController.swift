//
//  MyanmarLens.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 20/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

final class MyanmarLensController: UIViewController {
    
    private let myView = MyanmarLensView(frame: UIScreen.main.bounds)
    override func loadView() { view = myView }
    
    private lazy var manager = MyanmaLensManager()
    
    var languagePair = LanguagePair(.my, .my) {
        didSet {
            guard languagePair != oldValue else { return }
            manager.languagePair = languagePair
            myView.languagePair = languagePair
            manager.reset()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.delegate = self
        myView.delegate = self
        languagePair = (Language.my, userDefaults.language)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        manager.engine.bindPreviewLayer(to: myView.previewView)
        manager.engine.regionOfInterest = myView.regionOfInterest.frame
        myView.previewView.layer.addSublayer(myView.regionOfInterest.layer)
        myView.fillOpaqueAroundAreaOfInterest()
    }
    
    deinit {
        print("Deinit")
    }
}

extension MyanmarLensController: MyanmaLensManagerDelegate {
    
    func lensManager(didGetRecognizedText text: String?) {
        myView.recognizedLabel.text = text
        myView.translatedResultLabel.text = "..."
    }
    
    func lensManager(didGetResultText text: String?) {
        myView.translatedResultLabel.text = text
    }
    
    func lensManager(engineIsRunning isRunning: Bool) {
        myView.engineIsRunning(isRunning: isRunning)
    }
}


extension MyanmarLensController: MyanmarLensViewDelegate {
    
    func myanmarLensView(didTapResetButton view: MyanmarLensView) {
        manager.reset()
    }
    func myanmarLensView(didTapActionButton start: Bool, view: MyanmarLensView) {
        manager.engineIsRunning = start
    }
    
    
    func myanmarLensView(didtapToggleLanguageButton view: MyanmarLensView) {
        languagePair = (languagePair.1, languagePair.0)
    }
    
    func myanmarLensView(didtapLeftButton view: MyanmarLensView) {
        
    }
    
    func myanmarLensView(didtapRightButton view: MyanmarLensView) {
        let picker = UIPickerView()
        picker.backgroundColor = UIColor.systemGray.withAlphaComponent(0.8)
        picker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(picker)

        picker.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        picker.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        picker.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        picker.delegate = self
        picker.dataSource = self
    }
    
    func myanmarLensView(didTapDoneButton view: MyanmarLensView) {
        dismiss(animated: true, completion: nil)
    }
}


extension MyanmarLensController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Language.all.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let language = Language.all[row]
        if self.languagePair.0 != language {
            self.languagePair = (languagePair.0, language)
            userDefaults.updateObject(for: userDefaults.toLanguage, with: language.rawValue)
            pickerView.constraints.forEach{ $0.isActive = false }
            pickerView.removeFromSuperview()
        }
        
    }
    
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let language = Language.all[row]
        return NSAttributedString(string: language.description, attributes: [.font: UIFont.monoSpacedFont, .foregroundColor: UIColor.systemYellow])
    }
}
