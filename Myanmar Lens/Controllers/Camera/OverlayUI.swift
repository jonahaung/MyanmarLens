//
//  CameraUIView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 28/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import SwiftUI
import UIKit

struct CameraUIViewRepresentable: UIViewRepresentable {
    
    let serviceManager: ServiceManager

    func makeUIView(context: Context) -> OverlayView {
        return serviceManager.overlayView
    }

    func updateUIView(_ uiView: OverlayView, context: Context) {
        uiView.videoPreviewLayer.frame = uiView.bounds
        uiView.updateLayerTransform()
        uiView.roiLayer.frame =  OcrService.roi.applying(uiView.visionTransform)
    }
}
