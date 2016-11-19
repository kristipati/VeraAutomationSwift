//
//  Scene.swift
//  Vera
//
//  Created by Scott Gruby on 10/21/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import PMJSON

class VeraScene: CustomStringConvertible {
    var id: Int?
    var active: Bool?
    var state: Int?
    var name: String?
    var roomID: Int?
    var comment: String?
    
    init(json: JSON) {
        id = json["id"]?.int
        active = json["active"]?.boolean
        state = json["state"]?.integer
        name = json["name"]?.string
        roomID = json["room"]?.integer
        comment = json["comment"]?.string
    }
    
    var description: String {
        var desc: String = "Name: "
        if self.name != nil {
            desc += self.name!
        }
        
        if self.id != nil {
            desc += " (\(self.id!))"
        }
        
        return desc
    }
}
