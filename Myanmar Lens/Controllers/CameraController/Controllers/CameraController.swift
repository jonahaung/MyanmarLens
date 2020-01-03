//
//  CameraController.swift
//  MathSolver
//
//  Created by Khoa Pham on 26.06.2018.
//  Copyright © 2018 onmyway133. All rights reserved.
//

import UIKit
import AVFoundation

protocol CameraControllerDelegate: class {
    var languagePair: LanguagePair { get set }
    func cameraController(didTapActionButton controller: CameraController)
    func cameraController(_ controller: CameraController, didChangRepeatState isRepeat: Bool)
    func cameraController(_ controller: CameraController, didUpdateLanguage pair: LanguagePair)
}

final class CameraController: UIViewController {
    
    private let activityIndicator: UIActivityIndicatorView = {
        $0.isUserInteractionEnabled = false
        $0.hidesWhenStopped = true
        $0.color = UIColor.white
        $0.sizeToFit()
        return $0
    }(UIActivityIndicatorView(style: .large))

    
    
    lazy var targetLanguage = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(didTapTargetLanguage(_:)))
    lazy var sourceLanguage = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(didTapSourceLanguage(_:)))
    lazy var flashLightButtonItem = UIBarButtonItem(image: UIImage(systemName: "lightbulb.slash.fill"), style: .plain, target: self, action: #selector(didTapFlashLight(_:)))
    lazy var switchLanguage = UIBarButtonItem(image: UIImage(systemName: "arrow.right.arrow.left"), style: .plain, target: self, action: #selector(didTapSwitchLanguage(_:)))
    
    private lazy var toggleButton: UISwitch = {
        $0.isOn = userDefaults.isRepeat
        $0.onTintColor = UIColor.systemFill
        $0.addTarget(self, action: #selector(handleRepeat(_:)), for: .valueChanged)
        return $0
    }(UISwitch())
    
    let overlayView: PreviewView = {
        $0.videoLayer.session = AVCaptureSession()
        return $0
    }(PreviewView())
    lazy var actionButton: UIButton = {
        $0.setPreferredSymbolConfiguration(.init(pointSize: 70, weight: .thin), forImageIn: .normal)
        $0.setImage(UIImage(systemName: "largecircle.fill.circle"), for: .normal)
        $0.sizeToFit()
        $0.addTarget(self, action: #selector(didTapActionButton(_:)), for: .touchUpInside)
        return $0
    }(UIButton(type: .custom))
    
    lazy var videoManager = VideoService()
    weak var delegate: CameraControllerDelegate?
    
    
    var safeAreaInsets: UIEdgeInsets = .zero {
        didSet {
            guard oldValue != self.safeAreaInsets else { return }
            var center = view.center
            center.y = view.bounds.height - self.safeAreaInsets.bottom
            actionButton.center = center
        }
    }
    
    override func loadView() {
        view = overlayView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    var regionOfInterest: CGRect {
        return overlayView.regionOfInterest
    }
    func setTheme(color: UIColor) {
        actionButton.tintColor = color
        overlayView.setThemeColor(color)
    }
    
    func loading(isLoading: Bool) {
        var center = view.bounds.center
        center.y = regionOfInterest.minY - activityIndicator.bounds.height/2
        activityIndicator.center = center
        if isLoading {
            activityIndicator.startAnimating()
        }else {
            activityIndicator.stopAnimating()
        }
    }
    
}

// Setup
extension CameraController {
    private func setup() {
        view.addSubview(actionButton)
        view.addSubview(activityIndicator)
    }
}

// Actions
extension CameraController {
    
    @objc private func handleRepeat(_ sender: UISwitch) {
        userDefaults.isRepeat = sender.isOn
        delegate?.cameraController(self, didChangRepeatState: userDefaults.isRepeat)
        let text = sender.isOn ? "Auto-repeat ON" : "Auto-repeat OFF"
        dropDownMessageBar.show(text: text, duration: 5)
    }
    
    @objc private func didTapFlashLight(_ sender: UIBarButtonItem) {
        SoundManager.playSound(tone: .Tock)
        guard let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch else { return }
        let isOn = device.torchMode == .on
        do {
            try device.lockForConfiguration()
            
            device.torchMode = isOn ? .off : .on
            device.unlockForConfiguration()
            let onImage = UIImage(systemName: "lightbulb.fill")
            let offImage = UIImage(systemName: "lightbulb.slash.fill")
            sender.image = isOn ? offImage : onImage
        } catch {
            print("Torch could not be used")
        }
        
    }
    
    @objc private func didTapActionButton(_ sender: UIButton) {
        delegate?.cameraController(didTapActionButton: self)
    }
    
    func getToolbarItems() -> [UIBarButtonItem] {
        return [flashLightButtonItem, switchLanguage,  UIBarButtonItem.flexibleSpace, UIBarButtonItem(customView: toggleButton)]
    }
    @objc private func didTapSwitchLanguage(_ sender: UIButton) {
        let old = userDefaults.languagePair
        let new = LanguagePair(old.target, old.source)
        userDefaults.languagePair = new
        delegate?.cameraController(self, didUpdateLanguage: new)
        let text = "Switched language to \(new.source.localName) to \(new.target.localName)"
        dropDownMessageBar.show(text: text, duration: 5)
    }
}
