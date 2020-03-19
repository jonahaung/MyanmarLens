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
            Text(setting.description).padding(10)
        }
        .font(.system(size: 22, weight: .medium, design: .monospaced))
    }
}
