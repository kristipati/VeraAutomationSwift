//
//  Scene.swift
//  Vera
//
//  Created by Scott Gruby on 10/21/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

public class Scene: Deserializable, Printable {
    public var id: Int?
    var active: Bool?
    var state: Int?
    public var name: String?
    public var roomID: Int?
    var comment: String?
    
    public required init(data: [String: AnyObject]) {
        id <-- data["id"]
        active <-- data["active"]
        name <-- data["name"]
        state <-- data["state"]
        roomID <-- data ["room"]
        comment <-- data ["comment"]
    }
    
    public var description: String {
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
