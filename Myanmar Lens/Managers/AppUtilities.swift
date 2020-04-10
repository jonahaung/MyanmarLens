//
//  AppUtilities.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 25/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit
import MessageUI
import StoreKit

final class AppUtilities: NSObject {
    
    static let shared = AppUtilities()
    
    static let dateFormatter_relative: RelativeDateTimeFormatter = {
        $0.dateTimeStyle = .named
        $0.unitsStyle = .short
        return $0
    }(RelativeDateTimeFormatter())
    
    static let dateFormatter: DateFormatter = {
        $0.dateStyle = .short
        $0.timeStyle = .none
        return $0
    }(DateFormatter())
    
    func gotoPrivacyPolicy() {
        guard let url = URL(string: "https://mmsgr-1b7a6.firebaseapp.com/MyanmarLens.html") else {
            return //be safe
        }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func rateApp() {
        SKStoreReviewController.requestReview()
    }
    
    func shareApp() {
        if let url = URL(string: "https://apps.apple.com/app/myanmar-lens/id1489326871") {
            url.shareWithMenu()
        }
    }
    
    func gotoDeviceSettings() {
        let url = URL(string: UIApplication.openSettingsURLString)!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
   
    func gotoContactUs() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setSubject("Myanmar Lens: Feedback")
            mail.setToRecipients(["jonahaung@gmail.com"])
            
            Navigator.present(mail)
        } else {
            // show failure alert
        }
    }
}

extension AppUtilities: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) {
            switch result {
            case .sent:
                AlertPresenter.show(title: "Thank you for contacting us. I will get back to you soon. Have a nice day.\nAung Ko Min")
            case .failed:
                AlertPresenter.show(title: "Failed to send Mail")
            default:
                break
            }
        }
    }
}



extension Equatable {
    func shareWithMenu() {
        let activity = UIActivityViewController(activityItems: [self], applicationActivities: nil)
        let isPad: Bool = UIDevice.current.userInterfaceIdiom == .pad
        
        let root = UIApplication.topViewController()?.view
        
        if isPad, let source = root {
           
            activity.popoverPresentationController?.sourceView = source
            activity.popoverPresentationController?.sourceRect = CGRect(x: source.bounds.midX, y: source.bounds.midY, width: 0, height: 0)
            activity.popoverPresentationController?.permittedArrowDirections = .down
            activity.popoverPresentationController?.permittedArrowDirections = .init(rawValue: 0)
        }
        SceneDelegate.sharedInstance?.window?.rootViewController?.present(activity, animated: true, completion: nil)
    }
}

extension Bundle {
    var version: String? {
        return self.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
