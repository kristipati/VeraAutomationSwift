//
//  ForwardServer.swift
//  Automation
//
//  Created by Scott Gruby on 10/5/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import Foundation

class ForwardServer : Deserializable {
    var hostName:String?
    var primary:Bool?
    
    required init(data: [String: AnyObject]) {
        hostName <<< data["hostName"]
        primary <<< data["primary"]
    }
    
}
