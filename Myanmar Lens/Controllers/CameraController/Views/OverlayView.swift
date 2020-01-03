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
//        $0.borderWidth = 0.5
//        $0.borderColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        $0.fillColor = nil
        return $0
    }(CAShapeLayer())
    
    let highlightLayer: CAShapeLayer = {
        $0.fillColor = nil
        $0.lineWidth = 1.5
        $0.strokeColor = UIColor.systemPink.cgColor
//        $0.lineDashPattern = [3, 6]
        $0.strokeColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        return $0
    }(CAShapeLayer())
   
    var visionTransform = CGAffineTransform.identity
    var lineLayerTransform = CGAffineTransform.identity
   var videoPreviewLayer = AVCaptureVideoPreviewLayer(session: AVCaptureSession())
//    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
//        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
//            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
//        }
//
//        return layer
//    }
    
//    var session: AVCaptureSession? {
//        get {
//            return videoPreviewLayer.session
//        }
//        set {
//            videoPreviewLayer.session = newValue
//        }
//    }
    
    // MARK: UIView
    
//    override class var layerClass: AnyClass {
//        return AVCaptureVideoPreviewLayer.self
//    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        videoPreviewLayer.videoGravity = .resize
        layer.addSublayer(videoPreviewLayer)
        videoPreviewLayer.frame = bounds
        layer.addSublayer(roiLayer)
        layer.addSublayer(highlightLayer)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
       
        videoPreviewLayer.frame = layer.bounds
        updateLayerTransform()
        roiLayer.frame = OcrService.roi.applying(visionTransform)
        animate()
    }
    
    func updateLayerTransform() {
        let outputRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let videoRect = videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: outputRect)
        let visible = videoRect.intersection(frame)
        let scaleT = CGAffineTransform(scaleX: visible.width, y: -visible.height)
        let translateT = CGAffineTransform(translationX: 0, y: visible.height)
        visionTransform = scaleT.concatenating(translateT)
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        animate()
    }
}
