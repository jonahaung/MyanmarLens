//
//  SwiftyTesseract.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 20/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//


import AVFoundation
import UIKit

class VideoService: AVManager {
    
    let sessionQueue = DispatchQueue(queueLabel: .session)
    
    private(set) var videoLayer: AVCaptureVideoPreviewLayer
    private(set) var captureSession: AVCaptureSession
    private var captureDevice: AVCaptureDevice?
    var cameraQuality: AVCaptureSession.Preset = .inputPriority
    
    weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate? {
        didSet {
            sessionQueue.async {
                self.configure(self.captureSession)
            }
        }
    }
    
    init(previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: AVCaptureSession())) {
        videoLayer = previewLayer
        captureSession = previewLayer.session!
        videoLayer.videoGravity = .resize
    }
    
    private func configure(_ captureSession: AVCaptureSession) {
        guard isAuthorized(for: .video) else { return }
        captureSession.sessionPreset = cameraQuality
        configureInput(for: captureSession)
        
        let connection = configureOutputConnection(for: captureSession)
        configureOutput(for: connection)
    }
    
    private func configureInput(for captureSession: AVCaptureSession) {
        captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        guard
            let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice!),
            captureSession.canAddInput(captureDeviceInput)
            else { return }
        captureSession.addInput(captureDeviceInput)
    }
    
    private func configureOutputConnection(for captureSession: AVCaptureSession) -> AVCaptureConnection? {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue(queueLabel: .videoOutput))
        
        guard captureSession.canAddOutput(videoOutput) else { return nil }
        captureSession.addOutput(videoOutput)
        let output = videoOutput.connection(with: .video)
        output?.preferredVideoStabilizationMode = .off
        return output
    }
    
    private func configureOutput(for captureConnection: AVCaptureConnection?) {
        guard
            let captureConnection = captureConnection,
            captureConnection.isVideoOrientationSupported
            else { return }
        
        captureConnection.videoOrientation = .portrait
    }
    
    private func suspendQueueAndConfigureSession() {
        sessionQueue.suspend()
        configure(captureSession)
        sessionQueue.resume()
    }
    
    let minimumZoom: CGFloat = 0.5
    let maximumZoom: CGFloat = 6
    var lastZoomFactor: CGFloat = 1.0
    
    @objc func setZoom(_ pinch: UIPinchGestureRecognizer) {
        guard let device = captureDevice else { return }
        let zoomFactor = pinch.scale
        var error:NSError!
        do{
            try device.lockForConfiguration()
            defer {device.unlockForConfiguration()}
            if (zoomFactor <= device.activeFormat.videoMaxZoomFactor) {

                let desiredZoomFactor:CGFloat = zoomFactor + atan2(pinch.velocity, 5.0);
                device.videoZoomFactor = max(1.0, min(desiredZoomFactor, device.activeFormat.videoMaxZoomFactor));
            }
            else {
                NSLog("Unable to set videoZoom: (max %f, asked %f)", device.activeFormat.videoMaxZoomFactor, zoomFactor);
            }
        }
        catch error as NSError{
            NSLog("Unable to set videoZoom: %@", error.localizedDescription);
        }
        catch _{
        }
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
            guard let strongSelf = self else { return }
            if granted {
                strongSelf.configure(strongSelf.captureSession)
                strongSelf.sessionQueue.resume()
            }
        }
    }
    
    
    
}
