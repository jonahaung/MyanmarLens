//
//  TermsAndConditions.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 26/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import SwiftUI

struct TermsAndConditions: View {
    
    @Binding var notDoneEULA: Bool
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading) {
                if notDoneEULA {
                    Text("End User License Agreement").font(.largeTitle).padding()
                }
                Text("Last updated: 26-November-2019").font(.subheadline).foregroundColor(.secondary).padding()
                Text(subHeadText).font(Font.system(.callout, design: .monospaced)).foregroundColor(.primary)
                Text(bodyText).font(Font.system(.body, design: .monospaced)).foregroundColor(.secondary)
            }.padding(5)
            if notDoneEULA {
                Button(action: {
                    self.agree()
                }) {
                    Text("I AGREE & CONTINUE").font(.title).foregroundColor(.blue)
                }.padding()
            }
            
        }
        .background(Image("background").resizable().scaledToFill())
        .navigationBarTitle("EULA")
    }
    
    private func agree() {
        userDefaults.updateObject(for: userDefaults.hasDoneEULA, with: true)
        notDoneEULA = false
    }
    
    private let subHeadText = """
    ➤   This End User License Agreement is between you and 'Myanmar Lens' App and governs use of this app made available through the Apple App Store.
    ➤   By installing the 'Myanmar Lens' App, you agree to be bound by this Agreement and understand that there is no tolerance for objectionable content.
    ➤   If you do not agree with the terms and conditions of this Agreement, you are not entitled to use the 'Myanmar Lens' App.

    """
    
    private let bodyText = """
    • Parties
     This Agreement is between you and 'Myanmar Lens' only, and not Apple, Inc. 'Apple'. Notwithstanding the foregoing, you acknowledge that Apple and its subsidiaries and third party beneficiaries of this Agreement and Apple has the right to enforce this Agreement against you. 'Myanmar Lens', not Apple, is solely responsible for the 'Myanmar Lens' and its content.

    • Pravicy
     We are determined to protect and maintain your privacy. We are privileged to be trusted with your 'Device Camera Usage Permission' and do not wish to jeopardize that trust.
     We do NOT access your Contacts, Location Services, Device's Microphone.
     We do NOT share your information with third parties, we do NOT access and share your email addresses or phone number with sponsors or any third parties, and we do NOT run exclusive ‘sponsored’, 'phone calls' or 'sms' on behalf of third parties.

    • Limited License
     'Myanmar Lens' grants you a limited, non-exclusive, non-transferable, revocable license to use the 'Myanmar Lens' App for your personal, non-commercial purpose. You may only use the 'Myanmar Lens' App on Apple devices that you own or control and as permitted by the App Store Terms of Service.

    • Age Restrictions
     By using 'Myanmar Lens' App, you represent and wrrant that
        (a) you are 12 years of age or older and you agree to be bound by this Agreement
        (b) if you are under 12 years of age, you have obtained verifiable consent from a parent or legal guardian and
        (c) your use of the 'Myanmar Lens' App does not violate any applicable law or regulation.
     Your access to to the 'Myanmar Lens' may be terminated without warning if we believe, in its sole discretion, that you are under the age of 12 years and have not obtained verifiable consent from a parent or legal guardian. If you are a parent or legal guardian and you provide your consent to your child's use of the 'Myanmar Lens' App, you agree to be bound by this Agreement in respect to your child's use of the 'Myanmar Lens' App.
    • Warranty
     'Myanmar Lens' disclaims all warranties about the 'Myanmar Lens' App to the fullest extent permitted by law. To the extent any warranty exits under law that cannot be disclaimed, 'Myanmar Lens', not Apple, shall be solely responsible for such warranty.

    • Maintenance and Support
      'Myanmar Lens' does provide minimal maintenance or support for it but not to the extent that any maintenance or support is required by applicable law, 'Myanmar Lens', not Apple, shall be obligated to furnish any such maintenance or support.

    • Product Claims
     'Myanmar Lens', not Apple, is responsible for addressing any claims by you relating to the 'Myanmar Lens' App or use of it, including, but not limited to:
        (i) any product liability claim
        (ii) any claim that the 'Myanmar Lens' fails to conform to any applicable legal or regulatory requirement and
        (iii) any claim arising under consumer protection or similar legislation.
     Nothing in this Agreement shall be deemed and admission that you may have such claims.

    • Third Party Intellectual Property Claims
     'Myanmar Lens' shall not be obligated to indemnify or defend you with respect to any third party claim arising out or relating to the 'Myanmar Lens' App. To the extent 'Myanmar Lens' is required to provide indemnification by applicable law, 'Myanmar Lens', not Apple, shall be solely responsible for the investigation, defense, settlement and discharge of any claim that the 'Myanmar Lens' App or your use of it infringes any third party intellectual property right.

    YOU EXPRESSLY ACKNOWLEDGE THAT YOU HAVE READ THIS EULA AND UNDERSTAND THE RIGHTS, OBLIGATIONS, TERMS AND CONDITIONS SET FORTH HEREIN.
    BY CLICKING ON THE 'I AGREE & CONTINUE' BUTTON, YOU EXPRESSLY CONSENT TO BE BOUND BY ITS TERMS AND CONDITIONS AND GRANT TO 'Myanmar Lens' THE RIGHTS SET FORTH HEREIN.
    """
}
