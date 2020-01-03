//
//  NSTError.swift
//  VanGogh'sEye
//
//  Created by Aung Ko Min on 2/1/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import Foundation

public enum NSTError : Error {
    case unknown
    case assetPathError
    case modelError
    case resizeError
    case pixelBufferError
    case predictionError
}

extension NSTError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        case .assetPathError:
            return "Model file not found"
        case .modelError:
            return "Model error"
        case .resizeError:
            return "Resizing failed"
        case .pixelBufferError:
            return "Pixel Buffer conversion failed"
        case .predictionError:
            return "CoreML prediction failed"
        }
    }
}
