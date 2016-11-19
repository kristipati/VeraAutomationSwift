//
//  User.swift
//  Automation
//
//  Created by Scott Gruby on 10/5/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import Foundation
import PMJSON

class VeraUser {
    var units:[VeraUnit]?
    
    
    init(json: JSON) {
        units = try? json.mapArray("units", VeraUnit.init(json:))
        if units == nil {
            units = try? json.mapArray("Devices", VeraUnit.init(json:))
        }
    }
}
