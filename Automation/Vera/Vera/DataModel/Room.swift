//
//  Room.swift
//  Vera
//
//  Created by Scott Gruby on 10/21/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

public func ==(lhs: VeraRoom, rhs: VeraRoom) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name
}

open class VeraRoom: Deserializable, CustomStringConvertible, Hashable {
    open var name:String?
    var id:Int?
    
    public required init(data: [String: AnyObject]) {
        name <-- data["name"]
        id <-- data["id"]
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
    
    open var hashValue : Int {
        get {
            if self.id == nil {
                return 0
            }
            return self.id!
        }
    }
}
