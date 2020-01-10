//
//  OverlayView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 29/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit
import AVFoundation

class OverlayView: UIView {

    let highlightLayer: CAShapeLayer = {
        $0.fillColor = nil
        $0.lineWidth = 1
        $0.strokeColor = UIColor.systemBlue.cgColor
        return $0
    }(CAShapeLayer())

    override class var layerClass: AnyClass { return AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { return layer as! AVCaptureVideoPreviewLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        videoPreviewLayer.session = AVCaptureSession()
        videoPreviewLayer.videoGravity = .resize
        videoPreviewLayer.addSublayer(highlightLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        highlightLayer.frame = bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {

    }
    
    func handle(highlightLayer box: Box) {
        highlightLayer.path = UIBezierPath(rect: box.cgrect).cgPath

    }
}
