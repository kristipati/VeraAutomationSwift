//
//  Scene.swift
//  Vera
//
//  Created by Scott Gruby on 10/21/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

open class VeraScene: Deserializable, CustomStringConvertible {
    open var id: Int?
    var active: Bool?
    var state: Int?
    open var name: String?
    open var roomID: Int?
    var comment: String?
    
    public required init(data: [String: AnyObject]) {
        id <-- data["id"]
        active <-- data["active"]
        name <-- data["name"]
        state <-- data["state"]
        roomID <-- data ["room"]
        comment <-- data ["comment"]
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
