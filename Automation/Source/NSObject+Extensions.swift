//
//  NSObject+Extensions.swift
//  Automation
//
//  Created by Scott Gruby on 9/15/17.
//  Copyright © 2017 Gruby Solutions. All rights reserved.
//

import Foundation

public extension NSObject {
    static func className() -> String {
        return String(describing: self)
    }
}
