//
//  OverlayView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 29/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit
import AVFoundation

final class OverlayView: UIView {
    
    let heighlightLayer: CornorRectView = {
//        $0.fillColor = nil
//        $0.lineWidth = 2
//        $0.strokeColor = UIColor.systemIndigo.cgColor
        return $0
    }(CornorRectView())

    
    let imageView: UIImageView = {
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return $0
    }(UIImageView())

    override class var layerClass: AnyClass { return AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { return layer as! AVCaptureVideoPreviewLayer }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.frame = bounds
        videoPreviewLayer.session = AVCaptureSession()
        addSubview(imageView)
        
        addSubview(heighlightLayer)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        heighlightLayer.frame = OcrService.roi.normalized().viewRect(for: bounds.size).insetBy(dx: 10, dy: 0)
        heighlightLayer.drawCornors()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let first = touches.first else { return }
        let location = first.location(in: self)
        if heighlightLayer.frame.contains(location) {
            SoundManager.playSound(tone: .Tock)
            imageView.image = nil
        }
    }

}
