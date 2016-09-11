//
//  Scene.swift
//  Vera
//
//  Created by Scott Gruby on 10/21/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import JSONHelper

open class VeraScene: Deserializable, CustomStringConvertible {
    open var id: Int?
    var active: Bool?
    var state: Int?
    open var name: String?
    open var roomID: Int?
    var comment: String?
    
    public required init(data: [String: AnyObject]) {
        _ = id <-- data["id"]
        _ = active <-- data["active"]
        _ = name <-- data["name"]
        _ = state <-- data["state"]
        _ = roomID <-- data ["room"]
        _ = comment <-- data ["comment"]
    }
    
    open var description: String {
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
