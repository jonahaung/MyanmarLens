//
//  DroupDownMessageBar.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 19/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

final class DropDownMessageBar: UIView {
    
    private var timer: Timer?
    
    private lazy var label: UILabel = {
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.lineBreakMode = .byWordWrapping
        $0.textColor = UIColor.white
        $0.font = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .medium)
        return $0
    }(UILabel())
    
    private var insets = UIEdgeInsets(top: 10, left: 13, bottom: 10, right: 13)
    var font = UIFont.systemFont(ofSize: 10) {
        didSet {
            guard oldValue != self.font else { return }
            label.font = font
            let lineHeight = (font.lineHeight / 3).rounded()
            insets = UIEdgeInsets(top: lineHeight, left: lineHeight*2, bottom: lineHeight, right: lineHeight*2)
            layer.cornerRadius = ((insets.top + insets.bottom + font.lineHeight) / 2)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = UIColor.tertiarySystemBackground
        addSubview(label)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.center = bounds.center
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
        print("DEINIT: DropDownMessageBar")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        SoundManager.playSound(tone: .Tock)
        hide()
    }
}


extension DropDownMessageBar {
    
    func show(at point: CGPoint, text: String, duration: TimeInterval) {
        
        guard let window = SceneDelegate.sharedInstance?.window  else { return }
        
        SoundManager.playSound(tone: .Tock)
        
        if duration > 0 {
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(self.hide), userInfo: nil, repeats: false)
        }
        
        font = UIFont.preferredFont(forTextStyle: .footnote)
        
        label.text = text
        let labelSize = label.sizeThatFits(CGSize(width: window.bounds.width - (insets.left+insets.right * 4), height: .greatestFiniteMagnitude))
        label.frame.size = labelSize
        let width = labelSize.width + insets.horizontal
        let height = labelSize.height + insets.vertical
        let size = CGSize(width: width, height: height)
        let origin = CGPoint(x: point.x - (width/2), y: point.y - height - 10)
        var preferredFrame = CGRect(origin: origin, size: size)
        
        if preferredFrame.origin.x < 5 {
            preferredFrame.origin.x = 5
        }
        if preferredFrame.origin.x > window.bounds.width - width - 5{
            preferredFrame.origin.x = window.bounds.width - width - 5
        }
        frame = preferredFrame
        
        transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        if self.superview == nil {
            window.addSubview(self)
            dropShadow()
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.9, options: [.beginFromCurrentState, .allowUserInteraction, .allowAnimatedContent], animations: {
            self.transform = .identity
        })
    }
    
    
    
    func show(text: String, duration: TimeInterval) {
        
        guard let window = SceneDelegate.sharedInstance?.window else { return }
        
        SoundManager.playSound(tone: .Tock)
        
        if duration > 0 {
            timer?.invalidate()
            timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(self.hide), userInfo: nil, repeats: false)
        }
        
        font = UIFont.monospacedSystemFont(ofSize: UIFont.buttonFontSize, weight: .bold)
        
        label.text = text
        
        let labelSize = label.sizeThatFits(CGSize(width: window.bounds.width - (insets.horizontal * 4), height: .greatestFiniteMagnitude))
        label.frame.size = labelSize
        let width = labelSize.width + insets.horizontal
        let height = labelSize.height + insets.vertical
        let ySpacing: CGFloat = 100
        
        frame = CGSize(width: width, height: height).bma_rect(inContainer: window.bounds, xAlignament: .center, yAlignment: .top, dx: 0, dy: ySpacing)
        
        
        transform = CGAffineTransform(translationX: 0, y: -(height + ySpacing))
       
        
        if self.superview == nil {
            SoundManager.vibrate(vibration: .warning)
            window.addSubview(self)
            self.dropShadow()
        }
       
        UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction, .allowAnimatedContent, .curveEaseInOut], animations: {
            self.transform = .identity
            
        })
    }
    
    @objc func hide() {
        timer?.invalidate()
        guard self.superview != nil  else { return }
        UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction, .allowAnimatedContent, .curveEaseInOut], animations: {
            self.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }){ _ in
            self.removeFromSuperview()
            self.transform = .identity
            self.label.text = nil
        }
    }
}

let dropDownMessageBar = DropDownMessageBar()


extension UIEdgeInsets {
    var vertical: CGFloat {
        return top + bottom
    }
    var horizontal: CGFloat {
        return left + right
    }
}

extension UIView {
    
    func dropShadow(scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.4
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 3
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
    
    func applyGradient(colors: [UIColor], locations: [NSNumber]? = nil, startPoint: CGPoint? = nil, endPoint: CGPoint? = nil) -> Void {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colors.map { $0.cgColor }
        gradient.locations = locations
        if let startPoint = startPoint, let endPoint = endPoint {
            gradient.startPoint = startPoint
            gradient.endPoint = endPoint
        }
        self.layer.insertSublayer(gradient, at: 0)
    }
    
    public enum ViewSide {
        case top
        case right
        case bottom
        case left
    }
}
