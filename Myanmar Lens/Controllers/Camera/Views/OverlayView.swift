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
    let imageView: UIImageView = {
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
    private let pathAnimation: CABasicAnimation = {
        $0.duration = 0.15
        return $0
    }(CABasicAnimation(keyPath: "path"))
    
    override class var layerClass: AnyClass { return CameraPriviewLayer.self }
    var videoPreviewLayer: CameraPriviewLayer { return layer as! CameraPriviewLayer }
    
    private let shapeLayer: CAShapeLayer = {
        $0.lineWidth = 3
        $0.lineCap = .round
        $0.strokeColor = UIColor.systemYellow.cgColor
        $0.fillColor = nil
        return $0
    }(CAShapeLayer())
    
    private let textLayer: CATextLayer = {
        $0.fontSize = UIFont.preferredFont(forTextStyle: .callout).pointSize
        $0.contentsScale = UIScreen.main.scale
        $0.font = UIFont.preferredFont(forTextStyle: .callout)
        $0.frame.size = CGSize(width: 150, height: $0.fontSize + 10)
        $0.alignmentMode = .center
        $0.isWrapped = true
        return $0
    }(CATextLayer())
    
    let displayLayer: CALayer = {
        return $0
    }(CALayer())
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.frame = bounds
        addSubview(blackFlashView)
        addSubview(imageView)
        layer.addSublayer(displayLayer)
        displayLayer.addSublayer(shapeLayer)
        displayLayer.addSublayer(textLayer)
        UIApplication.shared.isIdleTimerDisabled = true
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
        imageView.image = nil
        shapeLayer.path = nil
        shapeLayer.strokeColor = UIColor.systemYellow.cgColor
        textLayer.string = nil
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
        
        textLayer.string = quad.text
        shapeLayer.strokeColor = quad.text.isEmpty ? UIColor.systemYellow.cgColor : UIColor.link.cgColor
        
        let viewQuad = quad.applying(videoPreviewLayer.layerTransform)
        let quadFrame = viewQuad.frame
        let position = CGPoint(x: quadFrame.midX, y: quadFrame.minY)
        apply(path: viewQuad.cornersPath.cgPath)
        textLayer.position = position
        
    }
    
    func apply(rectangle quad: Quadrilateral?) {
        guard let thisQuad = quad else {
            shapeLayer.path = nil
            
            return
        }
        textLayer.string = nil
        shapeLayer.lineWidth = 2
        shapeLayer.strokeColor = UIColor.systemBlue.cgColor
        shapeLayer.path = thisQuad.applying(videoPreviewLayer.layerTransform).rectanglePath.cgPath
    }
    
    func apply(path: CGPath?) {
        shapeLayer.add(pathAnimation, forKey: "path")
        shapeLayer.path = path
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return OcrService.roi.applying(videoPreviewLayer.layerTransform).contains(point)
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


