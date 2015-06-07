//
//  User.swift
//  Automation
//
//  Created by Scott Gruby on 10/5/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import Foundation

class User : Deserializable {
    var units:[Unit]?
    required init(data: [String: AnyObject]) {
        if (data["units"] != nil) {
            units <-- data["units"]
        }
        else if (data["Devices"] != nil) {
            units <-- data["Devices"]
        }
    }

}
