//
//  SettingCell.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 26/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import SwiftUI

struct SettingCell: View {
    
    let setting: Setting
    var body: some View {
        HStack{
            Image(systemName: setting.imageName).padding(.horizontal)
            Text(setting.description)
        }
        .font(.system(size: 22, weight: .medium, design: .monospaced))
    }
}
