//
//  User.swift
//  Automation
//
//  Created by Scott Gruby on 10/5/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import Foundation
import JSONHelper

class VeraUser : Deserializable {
    var units:[VeraUnit]?
    required init(data: [String: AnyObject]) {
        if (data["units"] != nil) {
            _ = units <-- data["units"]
        }
        else if (data["Devices"] != nil) {
            _ = units <-- data["Devices"]
        }
    }

}