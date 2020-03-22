//
//  ImageScannerScan.swift
//  BalarSarYwat
//
//  Created by Aung Ko Min on 3/2/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import UIKit

public struct ImageScannerScan {
    public enum ImageScannerError: Error {
        case failedToGeneratePDF
    }
    
    public var image: UIImage
    
    public func generatePDFData(completion: @escaping (Result<Data, ImageScannerError>) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            if let pdfData = self.image.pdfData() {
                completion(.success(pdfData))
            } else {
                completion(.failure(.failedToGeneratePDF))
            }
        }
        
    }
    
    mutating func rotate(by rotationAngle: Measurement<UnitAngle>) {
        guard rotationAngle.value != 0, rotationAngle.value != 360 else { return }
        image = image.rotated(by: rotationAngle) ?? image
    }
}
