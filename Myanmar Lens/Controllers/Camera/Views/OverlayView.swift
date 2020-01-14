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
    
    let heighlightLayer: CAShapeLayer = {
        $0.fillColor = nil
//        $0.lineDashPattern = [7]
        $0.lineWidth = 2
        $0.strokeColor = UIColor.systemIndigo.cgColor
        return $0
    }(CAShapeLayer())
    
    let roiView: ShapeView = {
        $0.backgroundColor = nil
        $0.layer.borderWidth = 2
        $0.layer.borderColor = UIColor.white.cgColor
        $0.layer.cornerRadius = 8
        return $0
    }(ShapeView())
    
    var highlightLayerFrame: CGRect = .zero {
        didSet {
            guard oldValue != self.highlightLayerFrame else { return }
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            heighlightLayer.lineWidth = 2
            heighlightLayer.path = UIBezierPath(rect: self.highlightLayerFrame).cgPath
            CATransaction.commit()
        }
    }
    
    override class var layerClass: AnyClass { return AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { return layer as! AVCaptureVideoPreviewLayer }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        videoPreviewLayer.session = AVCaptureSession()
        videoPreviewLayer.videoGravity = .resize
        videoPreviewLayer.addSublayer(heighlightLayer)
        addSubview(roiView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        heighlightLayer.frame = bounds
//        roiView.frame = OcrService.roi.normalized().viewRect(for: self.bounds.size)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


class ShapeView: UIView {
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        addGestureRecognizer(pan)
        addGestureRecognizer(pinch)
    }
    // We need to implement init(coder) to avoid compilation errors
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didPan(_ sender: UIPanGestureRecognizer) {
        
        self.superview!.bringSubviewToFront(self)
        
        let translation = sender.translation(in: self )
        
        self.center.x += translation.x
        self.center.y += translation.y
        
        sender.setTranslation(.zero, in: self)
    }
    
    @objc private func didPinch(_ sender: UIPinchGestureRecognizer) {
        
        self.superview!.bringSubviewToFront(self)
        
        let scale = sender.scale
        
        self.transform = self.transform.scaledBy(x: scale, y: scale)
        
        sender.scale = 1.0
    }
}
