//
//  CameraController+Helpers.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 30/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

extension CGRect {
    
    var area: CGFloat {
        return self.width * self.height
    }
    
    func scaleUp(scaleUp: CGFloat) -> CGRect {
        let biggerRect = self.insetBy(
            dx: -self.size.width * scaleUp,
            dy: -self.size.height * scaleUp
        )
        
        return biggerRect
    }

}
extension UIViewController {
    func add(childController: UIViewController) {
        childController.willMove(toParent: self)
        view.addSubview(childController.view)
        childController.didMove(toParent: self)
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
    
    func all(_ condition: (Iterator.Element) -> Bool) -> Bool {
        for x in self where !condition(x) {
            return false
        }
        return true
    }
    
    func some(_ condition: (Iterator.Element) -> Bool) -> Bool {
        for x in self where condition(x) {
            return true
        }
        return false
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
