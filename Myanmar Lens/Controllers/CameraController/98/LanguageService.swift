//
//  LanguageService.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 11/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit
import AVFoundation
import NaturalLanguage

protocol LanguageServiceDelegate: class {
    func languageService(_ service: LanguageServiece, didUpdateLanguagePair pair: LanguagePair)
}

final class LanguageServiece {
    
    weak var delegate: LanguageServiceDelegate?
    private var isActive = true
    var languagePair: LanguagePair = LanguagePair(.undetermined, .undetermined) {
        didSet {
            guard oldValue != self.languagePair else { return }
            DispatchQueue.main.async {
                self.delegate?.languageService(self, didUpdateLanguagePair: self.languagePair)
            }
            
        }
    }
    
    private let model = LanguageDetector_1()
  
    
    func handle(_ pixelBuffer: CVImageBuffer) {
        do {
            let x = try model.prediction(image: pixelBuffer)
            let language = NLLanguage(x.classLabel)
            languagePair = LanguagePair(language, languagePair.target)
        }catch { print(error) }
    }
    
    func handle(sampleBuffer: CMSampleBuffer) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        handle(pixelBuffer)
        
    }
    
    func reset() {
        isActive = true
    }
}
