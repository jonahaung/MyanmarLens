//
//  CaptureSession+Flash.swift
//  WeScan
//
//  Created by Julian Schiavo on 28/11/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Extension to CaptureSession to manage the device flashlight
extension CaptureSession {
    /// The possible states that the current device's flashlight can be in
    enum FlashState: Int, CaseIterable {
        case on, off
        
        var label: String {
            switch self {
            case .on:
                return "ON"
            case .off:
                return "OFF"
            }
        }
        
        var iconName: String {
            switch self {
            case .on:
                return "bolt.fill"
            case .off:
                return "bolt.slash"
            }
        }
    }
    
    /// Toggles the current device's flashlight on or off.
    func toggleFlash() {
        guard let device = device, device.isTorchAvailable else { return }
        
        do {
            try device.lockForConfiguration()
        } catch {
            print(error)
        }
        
        defer {
            device.unlockForConfiguration()
        }
        
        if device.torchMode == .on {
            device.torchMode = .off
        } else if device.torchMode == .off {
            device.torchMode = .on
        }
    }
    
    var currentState: FlashState {
        guard let device = device, device.isTorchAvailable else { return .off }
        return device.torchMode == .on ? .on : .off
    }
}

