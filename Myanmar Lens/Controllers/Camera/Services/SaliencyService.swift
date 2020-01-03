//
//  SaliencyService.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 29/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation
import AVKit
import Vision

protocol SaliencyServiceDelegate: class {
    func saliencyService(_ service: SaliencyService, didGetStableBox boundingBox: CGRect)
}

final class SaliencyService: NSObject {
    
    weak var delegate: SaliencyServiceDelegate?
    
    private let overlayView: OverlayView
    let lineLayer: CAShapeLayer
    
    private let attentionBasedRequest = VNGenerateAttentionBasedSaliencyImageRequest()
    private let objestBasedRequest = VNGenerateObjectnessBasedSaliencyImageRequest()
    private let context = CIContext(options: nil)
    var observation: VNSaliencyImageObservation?
    private let requestHandler = VNSequenceRequestHandler()
    var isTextProcessing = true
    var previousBox = CGRect.zero.box
    
    private var foundStabelSize = false
    var isAttentionBased = userDefaults.isAttentionBased {
        didSet {
            lineLayer.borderColor = self.isAttentionBased ? #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1) : #colorLiteral(red: 1, green: 0.5781051517, blue: 0, alpha: 1)
            isTextProcessing = false
        }
    }
    
    init(_overlayView: OverlayView) {
        overlayView = _overlayView
        lineLayer = _overlayView.highlightLayer
        
        super.init()
    }
}

extension SaliencyService {
    
    func handle(_ pixelBuffer: CVImageBuffer, isStopped: Bool) {

        let request = isAttentionBased ? attentionBasedRequest : objestBasedRequest
        
        do {
            try requestHandler.perform([objestBasedRequest], on: pixelBuffer, orientation: .up)
        }catch {
            print(error)
            return
        }
        
        observation = request.results?.first as? VNSaliencyImageObservation
        
        guard var salientObjects = self.observation?.salientObjects else { return }
        salientObjects = salientObjects.sorted{ $0.boundingBox.area > $1.boundingBox.area }
        guard let first = salientObjects.first else { return }
        let boundingBox = first.boundingBox
        let lineLayerFrame = boundingBox.applying(self.overlayView.visionTransform).integral
        
        guard !isStopped else {
            DispatchQueue.main.async {
                self.lineLayer.frame = lineLayerFrame
            }
            return
        }
        let newBox = Box(lineLayerFrame, trashold: 20)
        let isSame = newBox.cgrect.width == previousBox.cgrect.width && newBox.cgrect.origin.y == previousBox.cgrect.origin.y
        previousBox = newBox
       
        DispatchQueue.main.async {
            if isSame {
                self.lineLayer.frame.origin = lineLayerFrame.origin
                self.delegate?.saliencyService(self, didGetStableBox: boundingBox)
            } else {
                self.overlayView.lineLayerTransform = CGAffineTransform(scaleX: lineLayerFrame.width, y: -lineLayerFrame.height).concatenating(CGAffineTransform(translationX: 0, y: lineLayerFrame.height))
                self.lineLayer.frame = lineLayerFrame
                
            }
            
        }
    }
    
    
    func createHeatMapMask(from observation: VNSaliencyImageObservation) -> CGImage? {
        let ciImage = getCiImage(from: observation)
        let vector = CIVector(x: 0, y: 0, z: 0, w: 1)
        let saliencyImage = ciImage.applyingFilter("CIColorMatrix", parameters: ["inputBVector": vector])
        return CIContext().createCGImage(saliencyImage, from: saliencyImage.extent)
    }
    
    func getCiImage(from observation: VNSaliencyImageObservation) -> CIImage {
        let pixelBuffer = observation.pixelBuffer
        return CIImage(cvPixelBuffer: pixelBuffer)
    }
    
}


extension SaliencyService: AVCaptureVideoDataOutputSampleBufferDelegate, MLHelpingProtocol {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
         guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        handle(pixelBuffer, isStopped: false)
    }
}
