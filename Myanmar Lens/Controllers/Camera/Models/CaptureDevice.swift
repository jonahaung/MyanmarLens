//
//  CaptureDevice.swift
//  WeScan
//
//  Created by Julian Schiavo on 28/11/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation
import AVFoundation

protocol CaptureDevice: class {
    func unlockForConfiguration()
    func lockForConfiguration() throws
    
    var torchMode: AVCaptureDevice.TorchMode { get set }
    var isTorchAvailable: Bool { get }
    
    var focusMode: AVCaptureDevice.FocusMode { get set }
    var focusPointOfInterest: CGPoint { get set }
    var isFocusPointOfInterestSupported: Bool { get }
    func isFocusModeSupported(_ focusMode: AVCaptureDevice.FocusMode) -> Bool
    
    var exposureMode: AVCaptureDevice.ExposureMode { get set }
    var exposurePointOfInterest: CGPoint { get set }
    var isExposurePointOfInterestSupported: Bool { get } 
    func isExposureModeSupported(_ exposureMode: AVCaptureDevice.ExposureMode) -> Bool
    
    var isSubjectAreaChangeMonitoringEnabled: Bool { get set }
}

extension AVCaptureDevice: CaptureDevice { }
