//
//  VideoQuality.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 17/3/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import Foundation
import AVFoundation

enum VideoQuality: Int, CaseIterable {
    case low, high
    
    var preset: AVCaptureSession.Preset {
        switch self{
        case .low:
            return .iFrame960x540
        case .high:
            return .iFrame1280x720
        }
    }
    
    var cgSize: CGSize {
        switch self{
        case .low:
            return CGSize(width: 540, height: 960)
        case .high:
            return CGSize(width: 720, height: 1280)
        }
    }
    
    var label: String {
        switch self{
        case .low:
            return "960x540"
        case .high:
            return "1280x720"
        }
    }
    
    static var current: VideoQuality {
        return VideoQuality(rawValue: userDefaults.videoQuality) ?? .high
    }
    
    var opposite: VideoQuality {
        return self == .low ? .high : .low
    }
}
