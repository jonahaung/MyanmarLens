//
//  CaptureSession.swift
//  WeScan
//
//  Created by Julian Schiavo on 23/9/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation
import AVFoundation

/// A class containing global variables and settings for this capture session
final class CaptureSession {
    
    static let current = CaptureSession()
    
    var device: CaptureDevice?
    var isEditing: Bool
    
    var isAutoScanEnabled: Bool
    
    /// The orientation of the captured image
    var editImageOrientation: CGImagePropertyOrientation
    
    private init(isAutoScanEnabled: Bool = true, editImageOrientation: CGImagePropertyOrientation = .up) {
        self.device = AVCaptureDevice.default(for: .video)
        
        self.isEditing = false
        self.isAutoScanEnabled = isAutoScanEnabled
        self.editImageOrientation = editImageOrientation
    }
    
}
