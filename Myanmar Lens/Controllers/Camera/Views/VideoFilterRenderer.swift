//
//  ComicFilter.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 1/4/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import Foundation
import CoreMedia
import CoreVideo
import CoreImage

enum FilterType {
    case CIHexagonalPixellate, CILineOverlay, Crystal, CIPhotoEffectChrome, CIHighlightShadowAdjust, CINoiseReduction, CIPhotoEffectNoir
    
    var ciFilterName: String {
        switch self {
        case .CIHexagonalPixellate:
            return "CIHexagonalPixellate"
        case .CILineOverlay:
            return "CILineOverlay"
        case .Crystal:
            return "CICrystallize"
        case .CIPhotoEffectChrome:
            return "CIPhotoEffectChrome"
        case .CIHighlightShadowAdjust:
            return "CIHighlightShadowAdjust"
        case .CINoiseReduction:
            return "CINoiseReduction"
        case .CIPhotoEffectNoir:
            return "CIPhotoEffectMono"
        }
    }
    
}

class VideoFilterRenderer: FilterRenderer {
    
    var filterType: FilterType = .CIHighlightShadowAdjust {
        didSet {
            guard oldValue != self.filterType else {
                return
            }
            isPrepared = false
        }
    }
    
    var imageSize: CGSize = .zero
    var description: String = "Rosy (Core Image)"
    
    var isPrepared = false
    
    private var ciContext: CIContext?
    
    private var filter: CIFilter?
    
    private var outputColorSpace: CGColorSpace?
    
    private var outputPixelBufferPool: CVPixelBufferPool?
    
    private(set) var outputFormatDescription: CMFormatDescription?
    
    private(set) var inputFormatDescription: CMFormatDescription?
    var type: FilterType = FilterType.Crystal
    
    /// - Tag: FilterCoreImageRosy
    func prepare(with description: CMFormatDescription, retainHint: Int) {
        reset()
        
        (outputPixelBufferPool, outputColorSpace, outputFormatDescription)
            = allocateOutputBufferPool(with: description, retainHint: retainHint)
        if outputPixelBufferPool == nil {
            return
        }
        inputFormatDescription = description
        ciContext = CIContext()
        filter = CIFilter(name: filterType.ciFilterName)
        
        switch filterType {
        case .CILineOverlay:
            filter?.setValue(0.1, forKey: "inputNRNoiseLevel")
            filter?.setValue(0.2, forKey: "inputNRSharpness")
            filter?.setValue(0.8, forKey: "inputThreshold")
            filter?.setValue(10, forKey: "inputEdgeIntensity")
            filter?.setValue(40, forKey: "inputContrast")
        default:
            filter?.setDefaults()
        }
        isPrepared = true
    }
    
    func reset() {
        ciContext = nil
        filter = nil
        outputColorSpace = nil
        outputPixelBufferPool = nil
        outputFormatDescription = nil
        inputFormatDescription = nil
        isPrepared = false
    }
    
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        guard let rosyFilter = filter,
            let ciContext = ciContext,
            isPrepared else {
                assertionFailure("Invalid state: Not prepared")
                return nil
        }
        
        let sourceImage = CIImage(cvImageBuffer: pixelBuffer)
        rosyFilter.setValue(sourceImage, forKey: kCIInputImageKey)
        
        guard let filteredImage = rosyFilter.value(forKey: kCIOutputImageKey) as? CIImage else {
            print("CIFilter failed to render image")
            return nil
        }
        
        var pbuf: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool!, &pbuf)
        guard let outputPixelBuffer = pbuf else {
            print("Allocation failure")
            return nil
        }
        
        // Render the filtered image out to a pixel buffer (no locking needed, as CIContext's render method will do that)
        ciContext.render(filteredImage, to: outputPixelBuffer, bounds: filteredImage.extent, colorSpace: outputColorSpace)
        return outputPixelBuffer
    }
}
