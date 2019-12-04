//
//  SwiftyTesseract.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 20/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//


public enum RecognitionReliability {

  case raw
  case tentative
  case verifiable
  case stable
  case solid
  
  var numberOfResults: Int {
    switch self {
    case .raw: return 1
    case .tentative: return 2
    case .verifiable: return 3
    case .stable: return 4
    case .solid: return 5
    }
  }
}
