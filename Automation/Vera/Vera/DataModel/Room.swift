//
//  Room.swift
//  Vera
//
//  Created by Scott Gruby on 10/21/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

public func ==(lhs: Room, rhs: Room) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name
}

public class Room: Deserializable, Printable, Hashable {
    public var name:String?
    var id:Int?
    
    public required init(data: [String: AnyObject]) {
        name <-- data["name"]
        id <-- data["id"]
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
    
    public var hashValue : Int {
        get {
            if self.id == nil {
                return 0
            }
            return self.id!
        }
    }
}
