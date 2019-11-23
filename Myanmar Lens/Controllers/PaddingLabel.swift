//
//  PaddingLabel.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 23/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

class PaddingLabel: UILabel {
    
    var insets: UIEdgeInsets = UIEdgeInsets(top: 3, left: 7, bottom: 3, right: 7)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    override var font: UIFont! {
        didSet {
            layer.cornerRadius = (font.lineHeight + insets.top) / 2
            
        }
    }
    func setup() {
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize {
        
        let superContentSize = super.intrinsicContentSize
        let width = superContentSize.width + insets.left + insets.right
        let heigth = superContentSize.height + insets.top + insets.bottom
        return CGSize(width: width, height: heigth)
    }
    
    // Override `sizeThatFits(_:)` method for Springs & Struts code
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let superSizeThatFits = super.sizeThatFits(size)
        let width = superSizeThatFits.width + insets.left + insets.right
        let heigth = superSizeThatFits.height + insets.top + insets.bottom
        return CGSize(width: width, height: heigth)
    }
}

