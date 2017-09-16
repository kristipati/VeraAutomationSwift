//
//  Scene.swift
//  Vera
//
//  Created by Scott Gruby on 10/21/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

class VeraScene: CustomStringConvertible, Decodable {
    var id: Int? // swiftlint:disable:this variable_name
    var active: Bool?
    var state: Int?
    var name: String?
    var roomID: Int?
    var comment: String?

    private enum CodingKeys: String, CodingKey {
        case id // swiftlint:disable:this variable_name
        case active
        case state
        case name
        case roomID = "room"
        case comment
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try? container.decode(Int.self, forKey: .id)
        self.active = container.decodeAsBoolean(key: .active)
        self.state = container.decodeAsInteger(key: .state)
        self.roomID = container.decodeAsInteger(key: .roomID)
        self.name = try? container.decode(String.self, forKey: .name)
        self.comment = try? container.decode(String.self, forKey: .comment)
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
