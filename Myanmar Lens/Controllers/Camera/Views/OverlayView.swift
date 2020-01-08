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
    
    let roiLayer: CAShapeLayer = {
//        $0.borderWidth = 2
//        $0.borderColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        $0.fillColor = nil
        return $0
    }(CAShapeLayer())
    
    let highlightLayer: CAShapeLayer = {
        $0.fillColor = nil
        $0.lineWidth = 1
        return $0
    }(CAShapeLayer())

    override class var layerClass: AnyClass { return AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { return layer as! AVCaptureVideoPreviewLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        videoPreviewLayer.session = AVCaptureSession()
        videoPreviewLayer.videoGravity = .resize
        videoPreviewLayer.addSublayer(roiLayer)
        videoPreviewLayer.addSublayer(highlightLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        videoPreviewLayer.frame = layer.bounds
        let size = CGSize(width: layer.bounds.width, height: layer.bounds.height * 0.7)
        roiLayer.frame = size.bma_rect(inContainer: layer.bounds, xAlignament: .center, yAlignment: .top)
        animate()
    }

    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        
       
    }
    
    func handle(highlightLayer box: Box) {
        highlightLayer.path = UIBezierPath(roundedRect: highlightLayer.bounds, cornerRadius: 5).cgPath
        highlightLayer.strokeColor = box.type.stokeColor.cgColor
        if box.type == .Busy {
            highlightLayer.position = box.cgrect.center
        }else {
            highlightLayer.frame = box.cgrect
        }
        
        animate()
    }
    private func animate() {
        roiLayer.sublayers?.forEach{ $0.removeFromSuperlayer() }

         for number in 1...10{
             let line = FireworkLayer()
            line.position = highlightLayer.position
             line.transform = CATransform3DMakeRotation(CGFloat.pi * 2 / CGFloat(6) * CGFloat(number), 0, 0, 1)
             roiLayer.addSublayer(line)
             line.animate()
         }

         // Slightly rotate the angle of the view so it changes slightly per instance
         let minOffset: UInt32 = 0
         let maxOffset: UInt32 = 200
         let rotation = CGFloat(arc4random_uniform(maxOffset - minOffset) + minOffset) / CGFloat(100)
         roiLayer.setAffineTransform(CGAffineTransform(rotationAngle: rotation))
    }
}
