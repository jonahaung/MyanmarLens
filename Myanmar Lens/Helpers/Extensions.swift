//
//  Extensions.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 20/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit


extension UIApplication {
    
    class func topViewController(_ viewController: UIViewController? = SceneDelegate.sharedInstance?.window?.rootViewController) -> UIViewController? {
        if let nav = viewController as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = viewController as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = viewController?.presentedViewController {
            return topViewController(presented)
        }
        
        return viewController
    }
}

extension UIFont {
    private static let MyanmarSanpya = "MyanmarSanpya"
    private static let MyanmarPhetsot = "MyanmarPhetsot"
    static let myanmarFont = UIFontMetrics.default.scaledFont(for: UIFont(name: UIFont.MyanmarSanpya, size: 20)!)
    static let myanmarFontBold = UIFontMetrics.default.scaledFont(for: UIFont(name: UIFont.MyanmarPhetsot, size: 25)!)
    
    static var monoSpacedFont: UIFont {
        let defaultFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let fontDescriptor = defaultFontDescriptor.withSymbolicTraits(.traitMonoSpace)
        fontDescriptor?.withDesign(.monospaced)
        let font: UIFont

        if let fontDescriptor = fontDescriptor {
            font = UIFont(descriptor: fontDescriptor, size: 22)
        } else {
            font = UIFont.monospacedSystemFont(ofSize: 22, weight: .medium)
        }

        return font
    }
    
}


extension UIBarButtonItem {
    
    static let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
}

extension Optional where Wrapped == String {
    var string: String {
        return self ?? String()
    }
}


extension Date {
    
    var relativeString: String {
        return AppUtilities.dateFormatter_relative.localizedString(for: self, relativeTo: Date())
    }
    var dateString: String {
        return AppUtilities.dateFormatter.string(from: self)
    }
}


enum HorizontalAlignment {
    case left
    case center
    case right
}

enum VerticalAlignment {
    case top
    case center
    case bottom
}

extension CGSize {
    
    init(_ round: CGFloat) {
        self.init(width: round, height: round)
    }
    
    func bma_rect(inContainer containerRect: CGRect, xAlignament: HorizontalAlignment, yAlignment: VerticalAlignment, dx: CGFloat = 0, dy: CGFloat = 0) -> CGRect {
        let originX, originY: CGFloat
        
        // Horizontal alignment
        switch xAlignament {
        case .left:
            originX = 0
        case .center:
            originX = containerRect.midX - self.width / 2.0
        case .right:
            originX = containerRect.maxX - self.width
        }
        
        // Vertical alignment
        switch yAlignment {
        case .top:
            originY = 0
        case .center:
            originY = containerRect.midY - self.height / 2.0
        case .bottom:
            originY = containerRect.maxY - self.height
        }
        
        return CGRect(origin: CGPoint(x: originX, y: originY).bma_offsetBy(dx: dx, dy: dy), size: self)
    }
    
    func rectCentered(at: CGPoint) -> CGRect{
        let dx = self.width/2
        let dy = self.height/2
        let origin = CGPoint(x: at.x - dx, y: at.y - dy )
        return CGRect(origin: origin, size: self)
    }
    
    func scaleBy(_ factor: CGFloat) -> CGSize{
        return CGSize(width: self.width*factor, height: self.height*factor)
    }
    var bounds: CGRect {
        return CGRect(origin: .zero, size: self)
    }
}
extension CGPoint {
    
    func bma_offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + dx, y: self.y + dy)
    }
}


extension UIView {
    func constraint(equalTo size: CGSize) {
        guard superview != nil else { return }
        translatesAutoresizingMaskIntoConstraints = false
        let constraints: [NSLayoutConstraint] = [
            widthAnchor.constraint(equalToConstant: size.width),
            heightAnchor.constraint(equalToConstant: size.height)
        ]
        NSLayoutConstraint.activate(constraints)
        
    }

    
    func fillSuperview() {
        guard let superview = self.superview else {
            return
        }
        translatesAutoresizingMaskIntoConstraints = false
        leftAnchor.constraint(equalTo: superview.leftAnchor).isActive = true
        rightAnchor.constraint(equalTo: superview.rightAnchor).isActive = true
        topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
    }
    
    func centerInSuperview() {
        guard let superview = self.superview else {
            return
        }
        translatesAutoresizingMaskIntoConstraints = false
        centerYAnchor.constraint(equalTo: superview.centerYAnchor).isActive = true
        centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
    }
    
    @discardableResult
    func addConstraints(_ top: NSLayoutYAxisAnchor? = nil, left: NSLayoutXAxisAnchor? = nil, bottom: NSLayoutYAxisAnchor? = nil, right: NSLayoutXAxisAnchor? = nil, topConstant: CGFloat = 0, leftConstant: CGFloat = 0, bottomConstant: CGFloat = 0, rightConstant: CGFloat = 0, widthConstant: CGFloat = 0, heightConstant: CGFloat = 0) -> [NSLayoutConstraint] {
        
        if self.superview == nil {
            return []
        }
        translatesAutoresizingMaskIntoConstraints = false
        
        var constraints = [NSLayoutConstraint]()
        
        if let top = top {
            let constraint = topAnchor.constraint(equalTo: top, constant: topConstant)
            constraint.identifier = "top"
            constraints.append(constraint)
        }
        
        if let left = left {
            let constraint = leftAnchor.constraint(equalTo: left, constant: leftConstant)
            constraint.identifier = "left"
            constraints.append(constraint)
        }
        
        if let bottom = bottom {
            let constraint = bottomAnchor.constraint(equalTo: bottom, constant: -bottomConstant)
            constraint.identifier = "bottom"
            constraints.append(constraint)
        }
        
        if let right = right {
            let constraint = rightAnchor.constraint(equalTo: right, constant: -rightConstant)
            constraint.identifier = "right"
            constraints.append(constraint)
        }
        
        if widthConstant > 0 {
            let constraint = widthAnchor.constraint(equalToConstant: widthConstant)
            constraint.identifier = "width"
            constraints.append(constraint)
        }
        
        if heightConstant > 0 {
            let constraint = heightAnchor.constraint(equalToConstant: heightConstant)
            constraint.identifier = "height"
            constraints.append(constraint)
        }
        
        constraints.forEach { $0.isActive = true }
        return constraints
    }
    
    func removeAllConstraints() {
        constraints.forEach { removeConstraint($0) }
    }
}

extension UIViewController {
    
    func addDefaultBackgroundImageView() {
        let background = UIImageView(image: UIImage(named: "background"))
        background.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        background.frame = view.bounds
        view.addSubview(background)
    }
}
