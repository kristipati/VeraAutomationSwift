//
//  JSON+Extensions.swift
//  Automation
//
//  Created by Scott Gruby on 11/19/16.
//  Copyright © 2016 Gruby Solutions. All rights reserved.
//

import Foundation
import PMJSON

extension JSON {
    var integer: Int? {
        if let temp = self.int {
            return temp
        } else if let tempString = self.string {
            return Int(tempString)
        }
        return nil
    }

    var boolean: Bool? {
        if let temp = self.bool {
            return temp
        } else if let temp = self.int {
            return temp == 1
        } else if let temp = self.string {
            return Int(temp) == 1
        }
        return nil
    }

    var doubleDouble: Double? {
        if let temp = self.double {
            return temp
        } else if let temp = self.string {
            return Double(temp)
        }
        
        return nil
    }

}
