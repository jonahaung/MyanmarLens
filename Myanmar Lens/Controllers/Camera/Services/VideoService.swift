//
//  SwiftyTesseract.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 20/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//


import AVFoundation
import UIKit

protocol VideoServiceDelegate: class {
    func videoService(_ service: VideoService, didOutput cvPixelBuffer: CVPixelBuffer)
    func videoService(_ service: VideoService, captureFrame cvPixelBuffer: CVPixelBuffer)
}

class VideoService: NSObject {
    
    weak var delegate: VideoServiceDelegate?
    private let sessionQueue = DispatchQueue(queueLabel: .session)
    private let videoOutputQueue = DispatchQueue(queueLabel: .videoOutput)
    private let videoLayer: CameraPriviewLayer
    var captureSession = AVCaptureSession()
    let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    private let videoOutput: AVCaptureVideoDataOutput = {
        $0.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        return $0
    }(AVCaptureVideoDataOutput())
    
    var videoQuality: VideoQuality = VideoQuality.current {
        didSet {
            suspendQueueAndConfigureSession()
        }
    }
    
    private var lastTimestamp = CMTime()
    var fps = 10
    private let shadowFilter = VideoFilterRenderer()
    
    init(_ _overlayView: OverlayView) {
        videoLayer = _overlayView.videoPreviewLayer
    }

    
    func configure() {
        guard
            isAuthorized(for: .video),
            let device = self.captureDevice,
            let captureDeviceInput = try? AVCaptureDeviceInput(device: device), captureSession.canAddInput(captureDeviceInput), captureSession.canAddOutput(videoOutput) else {
                return
        }
        
        captureSession.sessionPreset = videoQuality.preset
        videoOutput.alwaysDiscardsLateVideoFrames = true
        captureSession.addInput(captureDeviceInput)
        captureSession.addOutput(videoOutput)
        let connection = videoOutput.connection(with: .video)
        if connection?.isVideoStabilizationSupported == true {
            connection?.preferredVideoStabilizationMode = .auto
        }else {
            connection?.preferredVideoStabilizationMode = .off
        }
        connection?.videoOrientation = .portrait
        
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        
        videoLayer.videoGravity = .resize
        videoLayer.session = captureSession
        
        try? device.lockForConfiguration()
        device.isSubjectAreaChangeMonitoringEnabled = true
        device.unlockForConfiguration()
    }
    
    private func suspendQueueAndConfigureSession() {
        sessionQueue.suspend()
        
        captureSession.sessionPreset = videoQuality.preset
        sessionQueue.resume()
    }
    
    
}

extension VideoService {
    private func isAuthorized(for mediaType: AVMediaType) -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized:
            return true
        case .notDetermined:
            requestPermission(for: mediaType)
            return false
        default:
            return false
        }
    }
    
    private func requestPermission(for mediaType: AVMediaType) {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: mediaType) { [weak self] granted in
            guard let self = self else { return }
            if granted {
                self.configure()
                self.sessionQueue.resume()
            }
        }
    }
}

extension VideoService {
    
    func start(_ completion: (()->Void)? = nil) {
        perform {
            self.captureSession.startRunning()
            completion?()
        }
    }
    func stop(_ completion: (()->Void)? = nil) {
        perform {
            self.captureSession.stopRunning()
            completion?()
        }
    }
    
    func  perform(_ block: @escaping (()->Void)) {
        sessionQueue.async(execute: block)
    }
    
    func sliderValueDidChange(_ value: Float) {
        do {
            try captureDevice?.lockForConfiguration()
            var zoomScale = CGFloat(value * 10.0)
            let zoomFactor = captureDevice?.activeFormat.videoMaxZoomFactor
            
            if zoomScale < 1 {
                zoomScale = 1
            } else if zoomScale > zoomFactor! {
                zoomScale = zoomFactor!
            }
            captureDevice?.videoZoomFactor = zoomScale
            captureDevice?.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 20)
            captureDevice?.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 15)
            captureDevice?.unlockForConfiguration()
        } catch {
            print("captureDevice?.lockForConfiguration() denied")
        }
    }
}

extension VideoService: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let deltaTime = timestamp - self.lastTimestamp
        if  deltaTime >= CMTimeMake(value: 1, timescale: Int32(self.fps)) {
            lastTimestamp = timestamp
            if let filteredBuffer = applyFilter(sampleBuffer, with: shadowFilter) {
                delegate?.videoService(self, didOutput: filteredBuffer)
            }
        }
    }
    
    private func applyFilter(_ sampleBuffer: CMSampleBuffer, with filter: VideoFilterRenderer) -> CVPixelBuffer? {
        if !filter.isPrepared {
            if let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)  {
                filter.prepare(with: formatDescription, retainHint: 3)
            }
            
        } else if let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            if CurrentSession.videoSize == .zero {
                CurrentSession.videoSize = CGSize(width: CVPixelBufferGetWidth(cvBuffer), height: CVPixelBufferGetHeight(cvBuffer))
            }
            return filter.render(pixelBuffer: cvBuffer)
        }
        return nil
    }
}
