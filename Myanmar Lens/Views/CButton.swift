//
//  CButton.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 24/2/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import SwiftUI

struct CButton<WhateverYouWant: View>: View {
    
    let action: () -> Void
    let content: WhateverYouWant
    
    init(_action: @escaping () -> Void, @ViewBuilder _content:() -> WhateverYouWant) {
        action = _action
        content = _content()
    }
    var body: some View {
        Button(action: {}) {
            content
                .padding()
                .frame(minWidth: 0, maxWidth: .infinity)
                .background(Capsule().fill(Color.blue))
        }
    }
}
