//
//  SwiftyTesseract.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 20/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//


import AVFoundation

class VideoManager: AVManager {
    
    private let sessionQueue = DispatchQueue(queueLabel: .session)
    private let mediaType: AVMediaType = .video
    private let videoOrientation: AVCaptureVideoOrientation = .portrait
    private let cameraPosition: AVCaptureDevice.Position = .back
    
    private(set) var videoLayer: AVCaptureVideoPreviewLayer
    private(set) var captureSession: AVCaptureSession
    
    var cameraQuality: AVCaptureSession.Preset = .high
    
    weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate? {
        didSet {
            suspendQueueAndConfigureSession()
        }
    }
    
    init(previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: AVCaptureSession())) {
        videoLayer = previewLayer
        captureSession = previewLayer.session!
        videoLayer.videoGravity = .resizeAspectFill
    }
    
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
    
    private func configure(_ captureSession: AVCaptureSession) {
        guard isAuthorized(for: mediaType) else { return }
        
        captureSession.sessionPreset = cameraQuality
        configureInput(for: captureSession)
        
        let connection = configureOutputConnection(for: captureSession)
        configureOutput(for: connection)
    }
    
    private func configureInput(for captureSession: AVCaptureSession) {
        guard
            let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: mediaType, position: cameraPosition),
            let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice),
            captureSession.canAddInput(captureDeviceInput)
            else { return }
        
        captureSession.addInput(captureDeviceInput)
    }
    
    private func configureOutputConnection(for captureSession: AVCaptureSession) -> AVCaptureConnection? {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue(queueLabel: .videoOutput))
        
        guard captureSession.canAddOutput(videoOutput) else { return nil }
        captureSession.addOutput(videoOutput)
        let output = videoOutput.connection(with: mediaType)
        output?.preferredVideoStabilizationMode = .off
        return output
    }
    
    private func configureOutput(for captureConnection: AVCaptureConnection?) {
        guard
            let captureConnection = captureConnection,
            captureConnection.isVideoOrientationSupported
            else { return }
        
        captureConnection.videoOrientation = videoOrientation
    }
    
    private func suspendQueueAndConfigureSession() {
        sessionQueue.suspend()
        configure(captureSession)
        sessionQueue.resume()
    }
}
