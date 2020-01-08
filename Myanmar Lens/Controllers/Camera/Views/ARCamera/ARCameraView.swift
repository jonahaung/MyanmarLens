//
//  ARCameraView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 8/1/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit
import ARKit
import SceneKit


struct ARCameraSUIView: UIViewRepresentable {
    
    let arManager: ARManager

    func makeUIView(context: Context) -> ARSCNView {
        return arManager.sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {

    }
}


