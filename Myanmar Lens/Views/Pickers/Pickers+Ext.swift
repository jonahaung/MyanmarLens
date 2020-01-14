//
//  Pickers+Ext.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 7/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

// MARK: - Initializers
extension UIAlertController {
    
   
    convenience init(style: UIAlertController.Style, source: UIView? = nil, title: String? = nil, message: String? = nil, tintColor: UIColor? = nil) {
        self.init(title: title, message: message, preferredStyle: style)
        
        let isPad: Bool = UIDevice.current.userInterfaceIdiom == .pad
        let root = UIApplication.topViewController()?.view
        
        if let source = source {
           
            popoverPresentationController?.sourceView = source
            popoverPresentationController?.sourceRect = source.bounds
        } else if isPad, let source = root, style == .actionSheet {
           
            popoverPresentationController?.sourceView = source
            popoverPresentationController?.sourceRect = CGRect(x: source.bounds.midX, y: source.bounds.midY, width: 0, height: 0)
            //popoverPresentationController?.permittedArrowDirections = .down
            popoverPresentationController?.permittedArrowDirections = .init(rawValue: 0)
        }
        
        if let color = tintColor {
            self.view.tintColor = color
        }
    }
}


// MARK: - Methods
extension UIAlertController {

    func show(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.setDefaultTheme()
            UIApplication.topViewController()?.present(self, animated: true, completion: completion)
        }
    }
    
    func addCancelAction() {
        addAction(title: "Cancel", style: .cancel, isEnabled: true)
    }
    
    func addAction(image: UIImage? = nil, title: String, color: UIColor? = nil, style: UIAlertAction.Style = .default, isEnabled: Bool = true, handler: ((UIAlertAction) -> Void)? = nil) {
      
        let action = UIAlertAction(title: title, style: style, handler: handler)
        action.isEnabled = isEnabled
        if let image = image {
            action.setValue(image, forKey: "image")
        }
        // button title color
        if let color = color {
            action.setValue(color, forKey: "titleTextColor")
        }
        addAction(action)
    }
    

    func set(title: String?, font: UIFont) {
        if title != nil {
            self.title = title
        }
        setTitle(font: font)
    }
    
    func setTitle(font: UIFont) {
        guard let title = self.title else { return }
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let attributedTitle = NSMutableAttributedString(string: title, attributes: attributes)
        setValue(attributedTitle, forKey: "attributedTitle")
    }
    
    func set(message: String?, font: UIFont) {
        if message != nil {
            self.message = message
        }
        setMessage(font: font)
    }
    
    func setMessage(font: UIFont) {
        guard let message = self.message else { return }
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let attributedMessage = NSMutableAttributedString(string: message, attributes: attributes)
        setValue(attributedMessage, forKey: "attributedMessage")
    }
    

    func set(vc: UIViewController?, width: CGFloat? = nil, height: CGFloat? = nil) {
        guard let vc = vc else { return }
        setValue(vc, forKey: "contentViewController")
        if let height = height {
            vc.preferredContentSize.height = height
            preferredContentSize.height = height
        }
    }
}

extension UIAlertController {
    
    func setDefaultTheme() {
        
        let isPad: Bool = UIDevice.current.userInterfaceIdiom == .pad
        
        if isPad, let source = UIApplication.topViewController()?.view {
           
            self.popoverPresentationController?.sourceView = source
            self.popoverPresentationController?.sourceRect = CGRect(x: source.bounds.midX, y: source.bounds.midY, width: 0, height: 0)
            self.popoverPresentationController?.permittedArrowDirections = .init(rawValue: 0)
        }
        view.tintColor = .label
        if let title = title {
            let attrTitle = NSAttributedString(string: title, attributes: [.font: UIFont.monospacedSystemFont(ofSize: 23, weight: .semibold)])
            setValue(attrTitle, forKey: "attributedTitle")
        }
        if let subtitle = message {
            let attrTitle = NSAttributedString(string: subtitle, attributes: [.font: UIFont.monospacedSystemFont(ofSize: 18, weight: .regular)])
            setValue(attrTitle, forKey: "attributedMessage")
        }
    }
}

