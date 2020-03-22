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
    func overlayView(didTapScreen view: OverlayView)
}
final class OverlayView: UIView {
    weak var delegate: OverlayViewDelegate?
    
    var focusRectangle: FocusRectangleView?
     let imageView: UIImageView = {
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        $0.isUserInteractionEnabled = false 
        $0.backgroundColor = nil
        return $0
    }(UIImageView())
    internal let blackFlashView: UIView = {
        $0.backgroundColor = UIColor.orange
        $0.layer.opacity = 0.8
        $0.isHidden = true
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return $0
    }(UIView())
    
    override class var layerClass: AnyClass { return CameraPriviewLayer.self }
    var videoPreviewLayer: CameraPriviewLayer { return layer as! CameraPriviewLayer }
    
    let quadView: QuadrilateralView = {
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return $0
    }(QuadrilateralView())
    
    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            guard newValue != imageView.image else { return }
            imageView.image = newValue
            zoomGestureController.image = newValue
            panGesture?.isEnabled = newValue != nil
        }
    }
    
    var zoomGestureController: ZoomGestureController!
    private var panGesture: UIPanGestureRecognizer?
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.frame = bounds
        quadView.frame = bounds
        addSubview(blackFlashView)
        addSubview(imageView)

        addSubview(quadView)
        UIApplication.shared.isIdleTimerDisabled = true
        
        zoomGestureController = ZoomGestureController(image: nil, quadView: quadView)
        
        panGesture = UIPanGestureRecognizer(target: zoomGestureController, action: #selector(zoomGestureController.handle(pan:)))
        panGesture?.isEnabled = false
        panGesture?.delegate = self
        addGestureRecognizer(panGesture!)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if let gesture = panGesture {
            removeGestureRecognizer(gesture)
        }
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let videoRect = videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1))
        let visible = videoRect.intersection(videoPreviewLayer.visibleRect)
        let scaleT = CGAffineTransform(scaleX: visible.width, y: -visible.height)
        let translateT = CGAffineTransform(translationX: visible.minX, y: visible.maxY)
        videoPreviewLayer.layerTransform = scaleT.concatenating(translateT)
    }

    
    func apply(_ quad: Quadrilateral?, isStable: Bool = false) {
       
        guard let quad = quad else {
            quadView.removeQuadrilateral()
            return
        }
        
       
        let transformedQuad = quad.applying(videoPreviewLayer.layerTransform)
    
         quadView.isStable = isStable
        quadView.drawQuadrilateral(quad: transformedQuad, animated: false)
        let location = transformedQuad.frame.center
        let convertedTouchPoint: CGPoint = quad.frame.center
        
        focusRectangle = FocusRectangleView(touchPoint: location)
        imageView.addSubview(focusRectangle!)
        
        do {
            try CaptureSession.current.setFocusPointToTapPoint(convertedTouchPoint)
        } catch {
            print(error)
            return
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard let touch = touches.first, !quadView.editable else { return }
        
        if image != nil {
            delegate?.overlayView(didTapScreen: self)
            return
        }
        SoundManager.playSound(tone: .Tock)
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
    
    func flashToBlack() {
        SoundManager.vibrate(vibration: .medium)
        bringSubviewToFront(blackFlashView)
        blackFlashView.isHidden = false
        blackFlashView.alpha = 1
        UIView.animate(withDuration: 0.4, animations: {
            self.blackFlashView.alpha = 0.1
        }) { done in
            if done {
                self.blackFlashView.isHidden = true
                self.sendSubviewToBack(self.blackFlashView)
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
        if gestureRecognizer == panGesture, quadView.isStable {
            
            return quadView.quad?.frame.insetBy(dx: -10, dy: -10).contains(location) == true
        }
        return OcrService.regionOfInterest.applying(videoPreviewLayer.layerTransform).contains(location)
    }
}
