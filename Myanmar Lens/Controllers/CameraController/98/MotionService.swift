//
//  MotionService.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 12/12/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation
import CoreMotion

protocol MotionServieceDelegate: class {
    func motionService(_ service: MotionService, didChangeMotionStatus isMoving: Bool)
}
final class MotionService {
    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    weak var delegate: MotionServieceDelegate?
    
    private var isMoving = false {
        didSet {
            guard oldValue != self.isMoving else { return }
            if !self.isMoving {
                DispatchQueue.main.async {

                    self.delegate?.motionService(self, didChangeMotionStatus: false)
                }
            }
        }
    }
    init() {
        guard manager.isAccelerometerAvailable else {
            return
        }
        
        manager.startDeviceMotionUpdates(to: queue) {[weak self] (data, error) in
            guard let self = self else { return }
            guard let data = data, error == nil else {
                return
            }
            self.isMoving = data.userAcceleration.z > 0.12 || data.userAcceleration.z < -0.12 || data.userAcceleration.x > 0.12 || data.userAcceleration.x < -0.12
        }

    }
}
