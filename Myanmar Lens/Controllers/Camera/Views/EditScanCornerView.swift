//
//  EditScanCornerView.swift
//  WeScan
//
//  Created by Boris Emorine on 3/5/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

/// A UIView used by corners of a quadrilateral that is aware of its position.
final class EditScanCornerView: UIView {
    
    let position: CornerPosition
    private(set) var isHighlighted = false
    
    lazy private var circleLayer: CAShapeLayer = {
        $0.fillColor = UIColor.systemBlue.cgColor
        $0.strokeColor = UIColor.systemBlue.cgColor
        $0.lineWidth = 1.0
        $0.opacity = 1
        return $0
    }(CAShapeLayer())
    
    init(frame: CGRect, position: CornerPosition) {
        self.position = position
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = true
        layer.addSublayer(circleLayer)
       isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2.0
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let bezierPath = UIBezierPath(ovalIn: rect.insetBy(dx: circleLayer.lineWidth, dy: circleLayer.lineWidth))
        circleLayer.frame = rect
        circleLayer.path = bezierPath.cgPath
    }
    
    func highlightWithImage(_ image: UIImage) {
        isHighlighted = true
        self.setNeedsDisplay()
    }
    
    
    
    func reset() {
        isHighlighted = false
        setNeedsDisplay()
    }
    
}
