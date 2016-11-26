//
//  ArrayExtension.swift
//  Automation
//
//  Created by Scott Gruby on 11/13/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

extension Array {
    mutating func removeObject<U: Equatable>(_ object: U) {
        var index: Int?
        for (idx, objectToCompare) in self.enumerated() {
            if let to = objectToCompare as? U {
                if object == to {
                    index = idx
                }
            }
        }

        if index != nil {
            remove(at: index!)
        }
    }
}
