//
//  CameraController.swift
//  MathSolver
//
//  Created by Khoa Pham on 26.06.2018.
//  Copyright © 2018 onmyway133. All rights reserved.
//

import UIKit
import AVFoundation
import NaturalLanguage
protocol CameraControllerDelegate: class {
    var languagePair: LanguagePair { get set }
}

final class CameraController: UIViewController {
   
    let actionButton: UIButton = {
        $0.setPreferredSymbolConfiguration(.init(pointSize: 70, weight: .semibold), forImageIn: .normal)
        $0.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        $0.tintColor = UIColor.brown
        $0.sizeToFit()
        return $0
    }(UIButton(type: .custom))
    
    let activityIndicator: UIActivityIndicatorView = {
        $0.isUserInteractionEnabled = false
        $0.hidesWhenStopped = true
        $0.color = UIColor.white
        $0.sizeToFit()
        return $0
    }(UIActivityIndicatorView(style: .large))
    
    private var pickerItems = [NLLanguage]()
    
    let targetLanguage = UIBarButtonItem(title: userDefaults.language.description.uppercased(), style: .done, target: nil, action: nil)
    let sourceLanguage = UIBarButtonItem(title: userDefaults.sourceLanguage.description.uppercased(), style: .done, target: nil, action: nil)
    let arrowButton = UIBarButtonItem(image: UIImage(systemName: "chevron.right.circle.fill"), style: .done, target: nil, action: nil)
    let flashLightButtonItem = UIBarButtonItem(image: UIImage(systemName: "bolt.fill", withConfiguration: UIImage.SymbolConfiguration.init(textStyle: .title2)), style: .done, target: nil, action: nil)
    weak var picker: UIPickerView?
    
    var languagePair: LanguagePair? { return delegate?.languagePair }

    weak var delegate: CameraControllerDelegate?
    let cameraLayer = AVCaptureVideoPreviewLayer(sessionWithNoConnection: AVCaptureSession())
    let overlayLayer = CameraOverlayLayer()
    lazy var videoManager = VideoManager(previewLayer: cameraLayer)
    
    private var flashLightOn = false {
        didSet {
            guard flashLightOn != oldValue else { return }
            guard let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                device.torchMode = flashLightOn ? .on : .off
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.layer.addSublayer(cameraLayer)
        view.layer.addSublayer(overlayLayer)
        view.addSubview(actionButton)
        view.addSubview(activityIndicator)
        addActions()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        cameraLayer.frame = view.bounds
        overlayLayer.frame = view.bounds
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        actionButton.center = CGPoint(x: view.center.x, y: overlayLayer.regionOfInterest.maxY + actionButton.bounds.height + 5)
        activityIndicator.center = CGPoint(x: view.center.x, y: overlayLayer.regionOfInterest.maxY-activityIndicator.bounds.height)
    }
    
}

extension CameraController {
    private func addActions() {
        targetLanguage.target = self
        targetLanguage.action = #selector(didTapTargetLanguage(_:))
        arrowButton.isEnabled = false
        sourceLanguage.target = self
        sourceLanguage.action = #selector(didTapSourceLanguage(_:))
        
        flashLightButtonItem.target = self
        flashLightButtonItem.action = #selector(didTapFlashLight(_:))
    }

    
    @objc private func didTapFlashLight(_ sender: UIBarButtonItem) {
        SoundManager.vibrate(vibration: .medium)
        flashLightOn.toggle()
        let imageName = flashLightOn ? "bolt.slash.fill" : "bolt.fill"
        sender.image = UIImage(systemName: imageName, withConfiguration: sender.image?.configuration)
    }
    
    @objc private func didTapReset(_ sender: Any) {
        SoundManager.vibrate(vibration: .medium)
        overlayLayer.sublayers?.forEach{ $0.removeFromSuperlayer() }
        for subview in view.subviews where subview is UILabel {
            subview.removeFromSuperview()
            
        }
    }


    private func addToFavorites() {
//        guard let text = myView.recognizedLabel.text, !text.isEmpty else { return }
//        let context = PersistanceManager.shared.viewContext
//        if let pair = TranslatePair.find(from: text, language: languagePair.1.rawValue, context: context) {
//            if pair.isFavourite {
//                AlertPresenter.show(title: "This translation is already in your favourites list", message: nil)
//                return
//            }
//            pair.isFavourite = true
//            context.saveIfHasChanges()
//            AlertPresenter.show(title: "Successfully Added To Favourites", message: nil)
//        }
    }
    
    
    @objc func didTapTargetLanguage(_ sender: Any) {
        guard let languagePair = self.languagePair else { return }
        SoundManager.vibrate(vibration: .medium)
        guard picker == nil else {
            picker?.removeFromSuperview()
            picker = nil
            return
        }
        pickerItems = Languages.all
       
        let picker: UIPickerView = {
            return $0
        }(UIPickerView())
        picker.frame = view.bounds
        picker.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        picker.delegate = self
        picker.dataSource = self
        
        view.addSubview(picker)
        
        picker.reloadAllComponents()
        picker.selectRow(Languages.all.firstIndex(of: languagePair.1) ?? 1, inComponent: 0, animated: true)
        
        self.picker = picker
    }
    
    @objc func didTapSourceLanguage(_ sender: Any) {
        guard let languagePair = self.languagePair else { return }
        SoundManager.vibrate(vibration: .medium)
        guard picker == nil else {
            picker?.removeFromSuperview()
            picker = nil
            return
        }
        pickerItems = Languages.source
        
        let picker: UIPickerView = {
            return $0
        }(UIPickerView())
        picker.frame = view.bounds
        picker.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        picker.delegate = self
        picker.dataSource = self
        
        view.addSubview(picker)
        
        picker.reloadAllComponents()
        picker.selectRow(Languages.source.firstIndex(of: languagePair.0) ?? 1, inComponent: 0, animated: true)
        
        self.picker = picker
    }
}

extension CameraController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerItems.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let languagePair = self.languagePair else { return }
        
        let isSelectingSoruce = pickerItems.count == Languages.source.count

        let language = pickerItems[row]

        var new = isSelectingSoruce ? LanguagePair(language, languagePair.1) : LanguagePair(languagePair.0, language)
        if new.0 == new.1 {
            SoundManager.vibrate(vibration: .error)
            if new.0 == .burmese {
                new.1 = .english
            }else {
                new.1 = .burmese
            }
        }
        userDefaults.language = new.1
        userDefaults.sourceLanguage = new.0
        delegate?.languagePair = new
    
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerItems[row].rawValue
    }
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let language = pickerItems[row]
        pickerView.subviews[1].isHidden = true
        pickerView.subviews[2].isHidden = true
        return NSAttributedString(string: language.description, attributes: [.font: UIFont.monospacedSystemFont(ofSize: 22, weight: .semibold), .foregroundColor: UIColor.white])
    }
}


extension CameraController {
    
    func getToolbarItems() -> [UIBarButtonItem] {
        return [flashLightButtonItem, UIBarButtonItem.flexibleSpace]
    }

}
