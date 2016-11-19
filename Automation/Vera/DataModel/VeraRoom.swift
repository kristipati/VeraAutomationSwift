//
//  Room.swift
//  Vera
//
//  Created by Scott Gruby on 10/21/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import PMJSON

struct VeraRoom: CustomStringConvertible, Hashable {
    var name:String?
    var id:Int?
    
    init(json: JSON) {
        id = json["id"]?.int
        name = json["name"]?.string
    }
    
    static func ==(lhs: VeraRoom, rhs: VeraRoom) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
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
    
    var hashValue : Int {
        get {
            if self.id == nil {
                return 0
            }
            return self.id!
        }
    }
}
