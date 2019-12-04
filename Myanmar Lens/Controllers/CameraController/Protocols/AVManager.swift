//
//  SwiftyTesseract.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 20/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import AVFoundation

protocol AVManager: class {
    var videoLayer: AVCaptureVideoPreviewLayer { get }
    var cameraQuality: AVCaptureSession.Preset { get set }
    var captureSession: AVCaptureSession { get }
    var delegate: AVCaptureVideoDataOutputSampleBufferDelegate? { get set }
}
