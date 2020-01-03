//
//  AlertPresenter.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 26/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

typealias Action = () -> Void
typealias ActionPair = (String, Action)

struct AlertPresenter {
    
    static func presentActionSheet(title: String? = nil , message: String? = nil, actions: [ActionPair]) {
        SoundManager.vibrate(vibration: .medium)
        let x = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        x.setDefaultTheme()
        
        actions.forEach{ action in
            let alertAction = UIAlertAction(title: action.0, style: .default) { _ in
                action.1()
                SoundManager.vibrate(vibration: .success)
            }
    
            x.addAction(alertAction)
        }
        
        x.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let nav = SceneDelegate.sharedInstance?.window?.rootViewController as? UINavigationController {
            
            nav.topViewController?.present(x, animated: true, completion: nil)
        }
//        UIApplication.topViewController()?.present(x, animated: true, completion: nil)
    }
    
    static func show(title: String, message: String? = nil) {
        let x = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        x.setDefaultTheme()
    
        x.addAction(UIAlertAction(title: "OK", style: .cancel))
        UIApplication.topViewController()?.present(x, animated: true, completion: nil)
        SoundManager.playSound(tone: .Tock)
    }
    
}

