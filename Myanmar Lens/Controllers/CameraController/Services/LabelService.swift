//
//  LabelService.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 3/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

final class LabelService {
    private var labels = [UILabel]()
    private let myanmarFont = UIFont.myanmarFont
    private let engFont = UIFont.preferredFont(forTextStyle: .title2)
    private var textColor = UIColor.darkText
    func handle(textRects: [TextRect], on view: UIView, isMyanmar: Bool){
        clearLabels()
        let font = isMyanmar ? myanmarFont : engFont
        textRects.forEach { (textRact) in
            let label = UILabel()
            let frame = view.convert(textRact.1, to: view)
            label.frame = frame
            label.textAlignment = .center
            label.font = font.withSize(textRact.1.height - 3)
            label.adjustsFontSizeToFitWidth = true
            label.textColor = textColor
            label.text = textRact.0
            view.addSubview(label)
            labels.append(label)
        }
    }
    func clearLabels() {
        labels.forEach{ $0.removeFromSuperview() }
    }
}
