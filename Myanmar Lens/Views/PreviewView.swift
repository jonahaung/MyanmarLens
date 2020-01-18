//
//  OverlayView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 13/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit
import AVFoundation

protocol PreviewCiewDelegate: class {
    func previewView(_ view: PreviewView, didChangeRegionOfInterest rect: CGRect)
    func previewView(_ view: PreviewView, gestureStageChanges isStart: Bool)
    var safeAreaInsets: UIEdgeInsets? { get }
}

class PreviewView: UIView, UIGestureRecognizerDelegate {
    
    private enum ControlCorner {
        case none
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
    
    private var cornorPoints: [CAShapeLayer] {
        return [topRight, topLeft, bottomLeft, topBottom]
    }
    
    var videoLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        return layer
    }
    
    weak var delegate: PreviewCiewDelegate?
    private var padding: UIEdgeInsets? { return delegate?.safeAreaInsets }
    
    private let regionOfInterestCornerTouchThreshold: CGFloat = 50
    private var minSize: CGFloat = 20
    private var regionOfInterestControlDiameter: CGFloat = 100
    private var regionOfInterestControlRadius: CGFloat {
        return regionOfInterestControlDiameter / 2.0
    }
    let background = CAShapeLayer()
    let line = CAShapeLayer()
    private let topLeft = CAShapeLayer()
    private let topRight = CAShapeLayer()
    private let topBottom = CAShapeLayer()
    private let bottomLeft = CAShapeLayer()
    @objc private(set) var regionOfInterest = CGRect.null {
        didSet {
            guard oldValue != self.regionOfInterest else { return }
            delegate?.previewView(self, didChangeRegionOfInterest: self.regionOfInterest)
        }
    }
    
    private var currenCircle: ControlCorner = .none {
        didSet {
            cornorPoints.forEach{ $0.removeFromSuperlayer() }
            switch self.currenCircle {
            case .bottomLeft:
                layer.addSublayer(topBottom)
            case .bottomRight:
                layer.addSublayer(bottomLeft)
            case .topRight:
                layer.addSublayer(topRight)
            case .topLeft:
                layer.addSublayer(topLeft)
            case .none:
                break
            }
        }
    }
    
    func setThemeColor(_ color: UIColor) {
        cornorPoints.forEach{
            $0.strokeColor = color.cgColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        background.fillRule = .evenOdd
        background.fillColor = UIColor.gray.cgColor
        background.opacity = 0.5
        layer.addSublayer(background)
        line.lineWidth = 1.5
        line.lineJoin = .round
        line.path = CGPath(roundedRect: regionOfInterest, cornerWidth: 3, cornerHeight: 3, transform: nil)
        line.fillColor = UIColor.clear.cgColor
        line.backgroundColor = UIColor.clear.cgColor
        line.strokeColor = UIColor.white.cgColor
        
        layer.addSublayer(line)
        
        let controlRect = CGRect(x: 0, y: 0, width: regionOfInterestControlDiameter, height: regionOfInterestControlDiameter)
        let path = UIBezierPath(ovalIn: controlRect).cgPath
        cornorPoints.forEach{
            $0.lineWidth = 2
            $0.fillColor = UIColor.white.cgColor
            $0.path = path
        }
        penGesture.delegate = self
        addGestureRecognizer(penGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func setROI(_ rect: CGRect) {
        let videoPreviewRect = videoLayer.layerRectConverted(fromMetadataOutputRect: rect).standardized
        let visibleRect = videoPreviewRect.intersection(frame)
        let oldRegionOfInterest = regionOfInterest
        var new = rect.standardized
        
        if currenCircle == .none {
            var xOffset: CGFloat = 0
            var yOffset: CGFloat = 0
            
            if !visibleRect.contains(new.origin) {
                xOffset = max(visibleRect.minX - new.minX, CGFloat(0))
                yOffset = max(visibleRect.minY - new.minY, CGFloat(0))
            }
            
            if !visibleRect.contains(CGPoint(x: visibleRect.maxX, y: visibleRect.maxY)) {
                xOffset = min(visibleRect.maxX - new.maxX, xOffset)
                yOffset = min(visibleRect.maxY - new.maxY, yOffset)
            }
            
            new = new.offsetBy(dx: xOffset, dy: yOffset)
        }
        
        new = visibleRect.intersection(new)
        
        if rect.size.width < minSize {
            switch currenCircle {
            case .topLeft, .bottomLeft:
                new.origin.x = oldRegionOfInterest.origin.x + oldRegionOfInterest.size.width - minSize
                new.size.width = minSize
                
            case .topRight:
                new.origin.x = oldRegionOfInterest.origin.x
                new.size.width = minSize
                
            default:
                new.origin = oldRegionOfInterest.origin
                new.size.width = minSize
            }
        }
        
        if rect.size.height < minSize {
            switch currenCircle {
            case .topLeft, .topRight:
                new.origin.y = oldRegionOfInterest.origin.y + oldRegionOfInterest.size.height - minSize
                new.size.height = minSize
                
            case .bottomLeft:
                new.origin.y = oldRegionOfInterest.origin.y
                new.size.height = minSize
                
            default:
                new.origin = oldRegionOfInterest.origin
                new.size.height = minSize
            }
        }
        
        regionOfInterest = new
        setNeedsLayout()
    }
    
    var isResizing: Bool {
        return penGesture.state == .changed
    }
    
    private lazy var penGesture: UIPanGestureRecognizer = {
        UIPanGestureRecognizer(target: self, action: #selector(PreviewView.resizeRegionOfInterestWithGestureRecognizer(_:)))
    }()
    
    @objc func resizeRegionOfInterestWithGestureRecognizer(_ resizeGesture: UIPanGestureRecognizer) {
        let location = resizeGesture.location(in: resizeGesture.view)
        let oldROI = regionOfInterest
        
        switch resizeGesture.state {
        case .began:
            willChangeValue(forKey: "regionOfInterest")
            currenCircle = cornerOfRect(oldROI, closestToPointWithinTouchThreshold: location)
            delegate?.previewView(self, gestureStageChanges: true)
            SoundManager.vibrate(vibration: .light)
        case .changed:
            
            var rect = oldROI
            
            switch currenCircle {
            case .none:
                
                let translation = resizeGesture.translation(in: resizeGesture.view)
                
                if regionOfInterest.contains(location) {
                    rect.origin.x += translation.x
                    rect.origin.y += translation.y
                }
                
                let normalised = CGRect(x: 0, y: 0, width: 1, height: 1)
                if !normalised.contains(videoLayer.captureDevicePointConverted(fromLayerPoint: location)) {
                    if location.x < regionOfInterest.minX || location.x > regionOfInterest.maxX {
                        rect.origin.y += translation.y
                    } else if location.y < regionOfInterest.minY || location.y > regionOfInterest.maxY {
                        rect.origin.x += translation.x
                    }
                }
                
                resizeGesture.setTranslation(CGPoint.zero, in: resizeGesture.view)
                
            case .topLeft:
                rect = CGRect(x: location.x, y: location.y, width: oldROI.size.width + oldROI.origin.x - location.x, height: oldROI.size.height + oldROI.origin.y - location.y)
                
            case .topRight:
                rect = CGRect(x: rect.origin.x, y: location.y, width: location.x - rect.origin.x,height: oldROI.size.height + rect.origin.y - location.y)
                
            case .bottomLeft:
                rect = CGRect(x: location.x, y: oldROI.origin.y, width: oldROI.size.width + oldROI.origin.x - location.x, height: location.y - oldROI.origin.y)
                
            case .bottomRight:
                rect = CGRect(x: oldROI.origin.x, y: oldROI.origin.y, width: location.x - oldROI.origin.x, height: location.y - oldROI.origin.y)
            }
            if let safe = self.padding, rect.minY < safe.top || rect.maxY > (bounds.height - safe.bottom){
                return
            }
            
            setROI(rect)
        case .ended:
            didChangeValue(forKey: "regionOfInterest")
            currenCircle = .none
            setNeedsLayout()
            userDefaults.regionOfInterestHeght = Float(regionOfInterest.height)
            delegate?.previewView(self, gestureStageChanges: false)
        default:
            return
        }
    }
    
    private func cornerOfRect(_ rect: CGRect, closestToPointWithinTouchThreshold point: CGPoint) -> ControlCorner {
        var closestDistance = CGFloat.greatestFiniteMagnitude
        var closest: ControlCorner = .none
        let corners: [(ControlCorner, CGPoint)] = [(.topLeft, rect.origin), (.topRight, CGPoint(x: rect.maxX, y: rect.minY)), (.bottomLeft, CGPoint(x: rect.minX, y: rect.maxY)), (.bottomRight, CGPoint(x: rect.maxX, y: rect.maxY))]
        
        for (corner, cornerPoint) in corners {
            let dX = point.x - cornerPoint.x
            let dY = point.y - cornerPoint.y
            let distance = sqrt((dX * dX) + (dY * dY))
            
            if distance < closestDistance {
                closestDistance = distance
                closest = corner
            }
        }
        
        if closestDistance > regionOfInterestCornerTouchThreshold {
            closest = .none
        }
        
        return closest
    }
    
    // MARK: UIView
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        line.frame = bounds
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let path = UIBezierPath(rect: bounds)
        path.append(UIBezierPath(rect: regionOfInterest))
        path.usesEvenOddFillRule = true
        background.path = path.cgPath
        
        line.path = UIBezierPath(roundedRect: regionOfInterest, cornerRadius: 3).cgPath
        
        let left = regionOfInterest.origin.x - regionOfInterestControlRadius
        let right = regionOfInterest.origin.x + regionOfInterest.size.width - regionOfInterestControlRadius
        let top = regionOfInterest.origin.y - regionOfInterestControlRadius
        let bottom = regionOfInterest.origin.y + regionOfInterest.size.height - regionOfInterestControlRadius
        
        topLeft.position = CGPoint(x: left, y: top)
        topRight.position = CGPoint(x: right, y: top)
        topBottom.position = CGPoint(x: left, y: bottom)
        bottomLeft.position = CGPoint(x: right, y: bottom)
        
        CATransaction.commit()
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {

        if gestureRecognizer == penGesture {
            let touchLocation = touch.location(in: gestureRecognizer.view)
            
            let paddedRegionOfInterest = regionOfInterest.insetBy(dx: -regionOfInterestCornerTouchThreshold, dy: -regionOfInterestCornerTouchThreshold)
            if !paddedRegionOfInterest.contains(touchLocation) {
                return false
            }
        }
        
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        if gestureRecognizer == penGesture {
            let touchLocation = gestureRecognizer.location(in: gestureRecognizer.view)
            
            let closestCorner = cornerOfRect(regionOfInterest, closestToPointWithinTouchThreshold: touchLocation)
            return closestCorner == .none
        }
        
        return false
    }
}
