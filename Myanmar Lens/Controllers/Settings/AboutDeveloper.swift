//
//  AboutDeveloper.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 26/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import SwiftUI
import MessageUI

struct AboutDeveloper: View {
    var body: some View {
        
        VStack(alignment: .center, spacing: 20) {
            Spacer()
            Text("App Developer").font(.system(.footnote, design: .monospaced))
            Text("Aung Ko Min").font(.system(.largeTitle, design: .monospaced)).padding(.vertical, 10)
            Text("The beauty you see in me is a reflection of you").font(.system(.body, design: .monospaced)).padding()
            
            List {
                Button(action: {
                    if let url = URL(string: "https://www.linkedin.com/in/aung-ko-min-jonah-382391176") {
                        if #available(iOS 10, *) {
                            UIApplication.shared.open(url, options: [:],completionHandler: { (success) in
                                print(success)
                            })
                        } else {
                            let success = UIApplication.shared.openURL(url)
                            print(success)
                        }
                    }
                }) {
                    Text("LinkedIn")
                }
                
                Button(action: {
                    if MFMailComposeViewController.canSendMail() {
                        let mail = MFMailComposeViewController()
                        
                        mail.setToRecipients(["jonahaung@gmail.com"])
                        
                        Navigator.present(mail)
                    }
                }) {
                    Text("Email")
                }
                Button(action: {
                    if let url = URL(string: "fb://profile/jonah.aung.12") {
                        if #available(iOS 10, *) {
                            UIApplication.shared.open(url, options: [:],completionHandler: { (success) in
                                print("Open fb://profile/jonah.aung.12: \(success)")
                            })
                        } else {
                            let success = UIApplication.shared.openURL(url)
                            print("Open fb://profile/538352816: \(success)")
                        }
                    }
                }) {
                    Text("Facebook")
                }
                Button(action: {
                    let twUrl = URL(string: "twitter://user?screen_name=JonahAungKoMin")!
                    let twUrlWeb = URL(string: "https://www.twitter.com/JonahAungKoMin")!
                    if UIApplication.shared.canOpenURL(twUrl){
                        UIApplication.shared.open(twUrl, options: [:],completionHandler: nil)
                    }else{
                        UIApplication.shared.open(twUrlWeb, options: [:], completionHandler: nil)
                    }
                }) {
                    Text("Twitter")
                }
            }
            .font(.system(.title, design: .monospaced))
        }
            
        .foregroundColor(.secondary)
            
        .background(Image("background").resizable().scaledToFill())
    }
}
