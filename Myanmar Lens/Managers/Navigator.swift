//
//  Navigator.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 26/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit

struct Navigator {
    
    static func push(_ vc: UIViewController) {
        UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
    }
    
    static func present(_ vc: UIViewController) {
        UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
    }
}
