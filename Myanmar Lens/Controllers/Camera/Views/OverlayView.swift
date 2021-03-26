//
//  OverlayView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 29/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit
import AVFoundation

protocol OverlayViewDelegate: class {
    func overlayView(didTapScreen view: OverlayView, canreset: Bool)
}
final class OverlayView: UIView {
    weak var delegate: OverlayViewDelegate?
    
    var focusRectangle: FocusRectangleView?
    let imageView: UIImageView = {
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return $0
    }(UIImageView())
    
    let trackLayer: CAShapeLayer = {
        $0.strokeColor = UIColor.systemPink.cgColor
        $0.lineWidth = 2
        $0.fillColor = nil
        return $0
    }(CAShapeLayer())
    override class var layerClass: AnyClass { return CameraPriviewLayer.self }
    var videoPreviewLayer: CameraPriviewLayer { return layer as! CameraPriviewLayer }
    
    private let pathAnimation: CABasicAnimation = {
        $0.duration = 0.2
        return $0
    }(CABasicAnimation(keyPath: "path"))
    
//    let quadView: QuadrilateralView = {
//        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        return $0
//    }(QuadrilateralView())
    
    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            guard newValue != image else { return }
            imageView.image = newValue
//            zoomGestureController.image = newValue
//            panGesture?.isEnabled = newValue != nil
//            quadView.displayingResults = newValue != nil
            
        }
    }
    
//    var zoomGestureController: ZoomGestureController!
//    private var panGesture: UILongPressGestureRecognizer?
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.frame = bounds
//        quadView.frame = bounds
        addSubview(imageView)
//        addSubview(quadView)
        imageView.layer.addSublayer(trackLayer)
//        zoomGestureController = ZoomGestureController(image: nil, quadView: quadView)
        
//        panGesture = UILongPressGestureRecognizer(target: zoomGestureController, action: #selector(zoomGestureController.handle(pan:)))
//        panGesture?.isEnabled = false
//        panGesture?.delegate = self
//        quadView.addGestureRecognizer(panGesture!)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
//        if let gesture = panGesture {
//            removeGestureRecognizer(gesture)
//        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let videoRect = videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1))
        let visible = videoRect.intersection(videoPreviewLayer.visibleRect)
        let scaleT = CGAffineTransform(scaleX: visible.width, y: -visible.height)
        let translateT = CGAffineTransform(translationX: visible.minX, y: visible.maxY)
        videoPreviewLayer.layerTransform = scaleT.concatenating(translateT)
        videoPreviewLayer.containerSize = imageView.bounds.size
    }
    var currentFrame = CGRect.zero
    
    func apply(_ quad: Quadrilateral?, isStable: Bool = false) {
        
        guard let quad = quad else {
            trackLayer.path = nil
            return
        }
        currentFrame = quad.frame
        trackLayer.path = quad.rectanglePath.cgPath
//        trackLayer.add(pathAnimation, forKey: "path")
        
//        let location = quad.frame.center
//        focusRectangle = FocusRectangleView(touchPoint: location)
//        imageView.addSubview(focusRectangle!)
//        SoundManager.vibrate(vibration: .light)
        
//        guard let quad = quad else {
//            quadView.removeQuadrilateral()
//            return
//        }
//        let canfoucs = true
//
//        quadView.drawQuadrilateral(quad: quad, animated: !canfoucs)
//        quadView.isStable = isStable
//        if canfoucs {
//            let location = quad.frame.center
//            focusRectangle = FocusRectangleView(touchPoint: location)
//            imageView.addSubview(focusRectangle!)
//            SoundManager.vibrate(vibration: .light)
//        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        SoundManager.playSound(tone: .Tock)
        guard let touch = touches.first else { return }
        
        let canReset = image != nil
        delegate?.overlayView(didTapScreen: self, canreset: canReset)
        if canReset {
            return
        }
        
        let location = touch.location(in: self)
        
        let convertedTouchPoint: CGPoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: location)
        
        focusRectangle = FocusRectangleView(touchPoint: location)
        imageView.addSubview(focusRectangle!)
        
        do {
            try CaptureSession.current.setFocusPointToTapPoint(convertedTouchPoint)
        } catch {
            print(error)
            return
        }
    }
    
    func flashToBlack(isCapture: Bool) {
        let blackFlashView: UIView = {
            $0.backgroundColor = isCapture ? UIColor.black : UIColor.white
            return $0
        }(UIView(frame: bounds))
        addSubview(blackFlashView)
        UIView.animate(withDuration: 0.3, animations: {
            blackFlashView.alpha = 0.1
        }) { done in
            if done {
                blackFlashView.removeFromSuperview()
            }
        }
    }
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return OcrService.regionOfInterest.applying(videoPreviewLayer.layerTransform).contains(point)
    }
}


extension OverlayView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: self)
//        if gestureRecognizer == panGesture, quadView.isStable {
//            
//            return quadView.quad?.frame.insetBy(dx: -10, dy: -10).contains(location) == true
//        }
        return OcrService.regionOfInterest.applying(videoPreviewLayer.layerTransform).contains(location)
    }
}
