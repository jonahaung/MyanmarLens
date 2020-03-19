//
//  CameraController+Helpers.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 30/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

extension CGRect {
    
    func scaleUp(scaleUp: CGFloat) -> CGRect {
        let biggerRect = self.insetBy(
            dx: -self.size.width * scaleUp,
            dy: -self.size.height * scaleUp
        )
        
        return biggerRect
    }

}

extension Sequence {

    func asyncForEach(completion: @escaping () -> (), block: (Iterator.Element, @escaping () -> ()) -> ()) {
        let group = DispatchGroup()
        let innerCompletion = { group.leave() }
        for x in self {
            group.enter()
            block(x, innerCompletion)
        }
        group.notify(queue: DispatchQueue.main, execute: completion)
    }
    
}

extension DispatchQueue {
  convenience init(queueLabel: DispatchQueue.Label) {
    self.init(label: queueLabel.rawValue)
  }
  
  enum Label: String {
    case session, videoOutput, ocr
  }
}
