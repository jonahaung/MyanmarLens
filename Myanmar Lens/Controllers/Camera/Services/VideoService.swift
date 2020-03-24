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
    func videoService(_ service: VideoService, didOutput sampleBuffer: CVImageBuffer)
}

class VideoService: NSObject {
    
    weak var videoServiceDelegate: VideoServiceDelegate?
    let sessionQueue = DispatchQueue(queueLabel: .session)
    static var videoSize = CGSize(width: 720, height: 1280)
    private var videoLayer: CameraPriviewLayer?
    var captureSession = AVCaptureSession()
    let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    private let videoOutput: AVCaptureVideoDataOutput = {
//        $0.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        return $0
    }(AVCaptureVideoDataOutput())
    var videoQuality: VideoQuality = VideoQuality.current {
        didSet {
           
            suspendQueueAndConfigureSession()
        }
    }
    var canOutputBuffer = false
    private var lastTimestamp = CMTime()
    var fps = 3
    
    func configure(layer: CameraPriviewLayer) {
        videoLayer = layer
        configure(captureSession)
    }
    
    func refresh() {
        sessionQueue.suspend()
        captureSession = AVCaptureSession()
        configure(captureSession)
        sessionQueue.resume()
    }
    
    private func configure(_ captureSession: AVCaptureSession) {
        
        guard
            isAuthorized(for: .video),
            let device = self.captureDevice,
            let captureDeviceInput = try? AVCaptureDeviceInput(device: device), captureSession.canAddInput(captureDeviceInput), captureSession.canAddOutput(videoOutput)
        else { return }
        VideoService.videoSize = videoQuality.cgSize
        captureSession.sessionPreset = videoQuality.preset
        videoOutput.alwaysDiscardsLateVideoFrames = false
        captureSession.addInput(captureDeviceInput)
        captureSession.addOutput(videoOutput)
        let connection = videoOutput.connection(with: .video)
        if connection?.isVideoStabilizationSupported == true {
            connection?.preferredVideoStabilizationMode = .off
        }else {
            connection?.preferredVideoStabilizationMode = .off
        }
        connection?.videoOrientation = .portrait
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(queueLabel: .videoOutput))
        videoLayer?.videoGravity = .resize
        videoLayer?.session = captureSession
        
        try? device.lockForConfiguration()
        device.isSubjectAreaChangeMonitoringEnabled = true
        device.unlockForConfiguration()
    }
    
    private func suspendQueueAndConfigureSession() {
        sessionQueue.suspend()
        VideoService.videoSize = videoQuality.cgSize
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
                self.configure(self.captureSession)
                self.sessionQueue.resume()
            }
        }
    }
}

extension VideoService {
    
    func start(_ completion: (()->Void)? = nil) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
           
            self.canOutputBuffer = true
            
            guard completion != nil else { return }
            completion?()
        }
    }
    func stop(_ completion: (()->Void)? = nil) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.canOutputBuffer = false
             guard completion != nil else { return }
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
         guard canOutputBuffer else { return }
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let deltaTime = timestamp - self.lastTimestamp
        if  deltaTime >= CMTimeMake(value: 1, timescale: Int32(self.fps)), let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            self.lastTimestamp = timestamp
           
            self.videoServiceDelegate?.videoService(self, didOutput: imageBuffer)
           
        }
        CMSampleBufferInvalidate(sampleBuffer)
        
    }
}
