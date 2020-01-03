//
//  LabelService.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 3/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

final class LabelService {
    
    private var labels = [AttributedLabel]()
    private let myanmarFont = UIFontMetrics.default.scaledFont(for: UIFont(name:"MyanmarPhetsot", size: 25)!)
    private let engFont = UIFontMetrics.default.scaledFont(for: UIFont(name:"ChalkboardSE-Regular", size: 25)!)
    var view = UIView()
    
    func handle(textRects: [TextRect]){
        clearLabels()
        
        for (i, textRect) in textRects.enumerated() {
            if let label = labels[exist: i] {
                updateLabel(label: label, frame: textRect.rect, text: textRect.text)
            }else {
                makeLabel(frame: textRect.rect, text: textRect.text)
            }
            
        }
        
    }
    
    func handle(translatedTextRects: [TranslateTextRect]){
        clearLabels()
        for (i, ttr) in translatedTextRects.enumerated() {
            let textRect = ttr.textRect
            if let label = labels[exist: i] {
                updateLabel(label: label, frame:  textRect.rect, text: ttr.translate)
            }else {
                 makeLabel(frame:  textRect.rect, text: ttr.translate)
                
            }
        }
    
    }
    var rects = [CGRect]()
    
    private func updateLabel(label: AttributedLabel, frame: CGRect, text: String) {
        label.isHidden = false
        let fontSize = min(27, frame.size.height.rounded(.down) - 6)
        label.font = text.EXT_isMyanmarCharacters ? myanmarFont.withSize(fontSize) : engFont.withSize(fontSize)
        label.text = text
        label.sizeToFit()
        label.center = frame.center
        if label.frame.origin.x < 0 {
            label.frame.origin.x = 2
        }
//        label.frame = label.intrinsicContentSize.bma_rect(inContainer: frame, xAlignament: .left, yAlignment: .top)
        rects.append(label.frame)
    }
    
    private func makeLabel(frame: CGRect, text: String) {
        let label = AttributedLabel()
        let fontSize = min(27, frame.size.height.rounded(.down) - 6)
        label.font = text.EXT_isMyanmarCharacters ? myanmarFont.withSize(fontSize) : engFont.withSize(fontSize)
        label.preferredMaxLayoutWidth = view.bounds.width - 5
        label.lineBreakMode = .byWordWrapping
        label.text = text
        label.sizeToFit()
        label.center = frame.center
        if label.frame.origin.x < 0 {
            label.frame.origin.x = 2
        }
        
        
        view.addSubview(label)
        labels.append(label)
        rects.append(label.frame)
    }
    
    func clearLabels() {
        rects.removeAll()
        for label in labels {
            label.text = nil
            label.isHidden = true
        }
    }

}
