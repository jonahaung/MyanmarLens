//
//  ResizableView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 13/1/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import UIKit

class ResizableView: UIView {
    
    
    static var kResizeThumbSize:CGFloat = 44.0
    private typealias `Self` = OverlayView
    
    var imageView = UIImageView()
    
    var isResizingLeftEdge:Bool = false
    var isResizingRightEdge:Bool = false
    var isResizingTopEdge:Bool = false
    var isResizingBottomEdge:Bool = false
    
    var isResizingBottomRightCorner:Bool = false
    var isResizingLeftCorner:Bool = false
    var isResizingRightCorner:Bool = false
    var isResizingBottomLeftCorner:Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemFill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //Define your initialisers here
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let currentPoint = touch.location(in: self)
            
            isResizingBottomRightCorner = (self.bounds.size.width - currentPoint.x < ResizableView.kResizeThumbSize && self.bounds.size.height - currentPoint.y < ResizableView.kResizeThumbSize);
            isResizingLeftCorner = (currentPoint.x < ResizableView.kResizeThumbSize && currentPoint.y < ResizableView.kResizeThumbSize);
            isResizingRightCorner = (self.bounds.size.width-currentPoint.x < ResizableView.kResizeThumbSize && currentPoint.y < ResizableView.kResizeThumbSize)
            isResizingBottomLeftCorner = (currentPoint.x < ResizableView.kResizeThumbSize && self.bounds.size.height - currentPoint.y < ResizableView.kResizeThumbSize)
            
            isResizingLeftEdge = (currentPoint.x < ResizableView.kResizeThumbSize)
            isResizingTopEdge = (currentPoint.y < ResizableView.kResizeThumbSize)
            isResizingRightEdge = (self.bounds.size.width - currentPoint.x < ResizableView.kResizeThumbSize)
            
            isResizingBottomEdge = (self.bounds.size.height - currentPoint.y < ResizableView.kResizeThumbSize)
            
            // do something with your currentPoint
            
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let currentPoint = touch.location(in: self)
            // do something with your currentPoint
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let currentPoint = touch.location(in: self)
            // do something with your currentPoint
            
            
            isResizingLeftEdge = false
            isResizingRightEdge = false
            isResizingTopEdge = false
            isResizingBottomEdge = false
            
            isResizingBottomRightCorner = false
            isResizingLeftCorner = false
            isResizingRightCorner = false
            isResizingBottomLeftCorner = false
            
        }
    }
}
