//
//  ImageScannerController.swift
//  WeScan
//
//  Created by Boris Emorine on 2/12/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import AVFoundation

public protocol ImageScannerControllerDelegate: NSObjectProtocol {

    func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults)
    func imageScannerControllerDidCancel(_ scanner: ImageScannerController)
    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error)
}

public final class ImageScannerController: UINavigationController {
    
    weak public var imageScannerDelegate: ImageScannerControllerDelegate?
    public var isMyanmar = true

    internal let blackFlashView: UIView = {
        $0.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        $0.isHidden = true
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIView())
    
    public required init(image: UIImage? = nil, delegate: ImageScannerControllerDelegate? = nil) {
        super.init(rootViewController: ScannerViewController())
        
        self.imageScannerDelegate = delegate
        
        self.view.addSubview(blackFlashView)
        setupConstraints()
        
      
        if let image = image {
            
            var detectedQuad: Quadrilateral?
        
            guard let ciImage = CIImage(image: image) else { return }
            let orientation = CGImagePropertyOrientation(image.imageOrientation)
            let orientedImage = ciImage.oriented(forExifOrientation: Int32(orientation.rawValue))
            ObjectDetector.rectangle(forImage: ciImage, orientation: orientation) { (quad) in
                detectedQuad = quad?.toCartesian(withHeight: orientedImage.extent.height)
                let editViewController = EditScanViewController(image: image, quad: detectedQuad, rotateImage: false)
                self.setViewControllers([editViewController], animated: true)
            }
        }
    }
    

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        let blackFlashViewConstraints = [
            blackFlashView.topAnchor.constraint(equalTo: view.topAnchor),
            blackFlashView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.bottomAnchor.constraint(equalTo: blackFlashView.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: blackFlashView.trailingAnchor)
        ]
        
        NSLayoutConstraint.activate(blackFlashViewConstraints)
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    internal func flashToBlack() {
        view.bringSubviewToFront(blackFlashView)
        blackFlashView.isHidden = false
        let flashDuration = DispatchTime.now() + 0.05
        DispatchQueue.main.asyncAfter(deadline: flashDuration) {
            self.blackFlashView.isHidden = true
        }
    }
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .fullScreen
//        overrideUserInterfaceStyle = .dark
//        navigationBar.tintColor = .white
//        navigationBar.isTranslucent = false
//        toolbar.tintColor = .white
    }
}
