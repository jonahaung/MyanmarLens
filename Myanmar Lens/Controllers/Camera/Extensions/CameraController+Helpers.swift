//
//  CameraController+Helpers.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 30/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit
import AVFoundation

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
        self.init(label: queueLabel.rawValue, attributes: [.concurrent], autoreleaseFrequency: .workItem)
    }
    
    enum Label: String {
        case session, videoOutput, ocr
    }
}


// stolen from Kingfisher: https://github.com/onevcat/Kingfisher/blob/master/Sources/ThreadHelper.swift
extension DispatchQueue {
   
    func safeAsync(_ block: @escaping ()->()) {
        if self === DispatchQueue.main && Thread.isMainThread {
            block()
        } else {
            async { block() }
        }
    }
}

typealias Task = (_ cancel : Bool) -> Void

@discardableResult func DispatchQueueDelay(_ time: TimeInterval, task: @escaping ()->()) ->  Task? {
    
    func dispatch_later(block: @escaping ()->()) {
        let t = DispatchTime.now() + time
        DispatchQueue.main.asyncAfter(deadline: t, execute: block)
    }
    var closure: (()->Void)? = task
    var result: Task?
    
    let delayedClosure: Task = {
        cancel in
        if let internalClosure = closure {
            if (cancel == false) {
                DispatchQueue.main.async(execute: internalClosure)
            }
        }
        closure = nil
        result = nil
    }
    
    result = delayedClosure
    
    dispatch_later {
        if let delayedClosure = result {
            delayedClosure(false)
        }
    }
    return result
}

extension UIDevice {
    static func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
