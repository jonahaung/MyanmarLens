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
    func overlayView(didClearScreen view: OverlayView)
}
final class OverlayView: UIView {
    weak var delegate: OverlayViewDelegate?
    
    var focusRectangle: FocusRectangleView?
    private let imageView: UIImageView = {
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        $0.backgroundColor = nil
        return $0
    }(UIImageView())
    internal let blackFlashView: UIView = {
        $0.backgroundColor = UIColor.orange.withAlphaComponent(0.8)
        $0.isHidden = true
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
           return $0
       }(UIView())
    
    override class var layerClass: AnyClass { return CameraPriviewLayer.self }
    var videoPreviewLayer: CameraPriviewLayer { return layer as! CameraPriviewLayer }
    let displayLayer: CALayer = {
        return $0
    }(CALayer())
    
    private let quadView: QuadrilateralView = {
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
            zoomGestureController.image = newValue ?? UIImage()
            quadView.editable = newValue != nil
            
        }
    }
    
    private var zoomGestureController: ZoomGestureController!
    private var panGesture: UIPanGestureRecognizer?
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.frame = bounds
        quadView.frame = bounds
        addSubview(blackFlashView)
        addSubview(imageView)
        layer.addSublayer(displayLayer)
        addSubview(quadView)
        UIApplication.shared.isIdleTimerDisabled = true
        
        zoomGestureController = ZoomGestureController(image: UIImage(), quadView: quadView)
        
        panGesture = UIPanGestureRecognizer(target: zoomGestureController, action: #selector(zoomGestureController.handle(pan:)))
        panGesture?.delegate = self
        addGestureRecognizer(panGesture!)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        displayLayer.frame = bounds
        let videoRect = videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1))
        let visible = videoRect.intersection(videoPreviewLayer.visibleRect)
        let scaleT = CGAffineTransform(scaleX: visible.width, y: -visible.height)
        let translateT = CGAffineTransform(translationX: visible.minX, y: visible.maxY)
        videoPreviewLayer.layerTransform = scaleT.concatenating(translateT)
    }
    
    
    func clear() {
        image = nil
        quadView.editable = false
        quadView.text = ""
        delegate?.overlayView(didClearScreen: self)
        if videoPreviewLayer.session?.isRunning == false {
            videoPreviewLayer.session?.startRunning()
        }
       
    }

    func apply(_ quad: Quadrilateral?) {
        guard let quad = quad else {
            clear()
            return
        }
    
        
        let viewQuad = quad.applying(videoPreviewLayer.layerTransform)
        quadView.text = quad.text
        quadView.drawQuadrilateral(quad: viewQuad, animated: true)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard let touch = touches.first else { return }
        SoundManager.playSound(tone: .Tock)
        
        let location = touch.location(in: self)
        
        let convertedTouchPoint: CGPoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: location)
        
        CaptureSession.current.removeFocusRectangleIfNeeded(focusRectangle, animated: true)
        
        focusRectangle = FocusRectangleView(touchPoint: location)
        imageView.addSubview(focusRectangle!)
        
        do {
            try CaptureSession.current.setFocusPointToTapPoint(convertedTouchPoint)
        } catch {
            print(error)
            return
        }
         clear()
       
    }

    func flashToBlack() {
        SoundManager.vibrate(vibration: .selection)
        
        bringSubviewToFront(blackFlashView)
        blackFlashView.isHidden = false
        let flashDuration = DispatchTime.now() + 0.05
        DispatchQueue.main.asyncAfter(deadline: flashDuration) {
            self.blackFlashView.isHidden = true
            self.sendSubviewToBack(self.blackFlashView)
            SoundManager.playSound(tone: .Typing)
        }
    }
}


extension OverlayView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGesture, let quad = quadView.quad {
            let location = gestureRecognizer.location(in: self)
            return quad.frame.scaleUp(scaleUp: 0.01).intersects(location.surroundingSquare(withSize: 70))
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}
