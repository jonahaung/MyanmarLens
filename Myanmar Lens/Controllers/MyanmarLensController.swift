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
    
    var languagePair = LanguagePair(.none, .none) {
        didSet {
            guard languagePair != oldValue else { return }
            manager.languagePair = languagePair
            myView.languagePair = languagePair
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.delegate = self
        myView.delegate = self
        languagePair = (Language.my, Language.en)
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
    }
    
    func lensManager(didGetResultText text: String?) {
        myView.translatedResultLabel.text = text
    }
    
    func lensManager(engineIsRunning isRunning: Bool) {
        let buttonImageName = isRunning ? "circle" : "circle.fill"
        myView.setActionButtonImage(withSystemName: buttonImageName)
    }
}


extension MyanmarLensController: MyanmarLensViewDelegate {
    
    func myanmarLensView(didtapToggleLanguageButton view: MyanmarLensView) {
        languagePair = (languagePair.1, languagePair.0)
    }
    
    func myanmarLensView(didtapLeftButton view: MyanmarLensView) {
        
    }
    
    func myanmarLensView(didtapRightButton view: MyanmarLensView) {
        
    }
    
    func myanmarLensView(didTapDoneButton view: MyanmarLensView) {
        dismiss(animated: true, completion: nil)
    }
    
    func myanmarLensView(didTapActionButton view: MyanmarLensView) {
        manager.engineIsRunning.toggle()
    }
}

