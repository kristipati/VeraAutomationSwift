//
//  Room.swift
//  Vera
//
//  Created by Scott Gruby on 10/21/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

struct VeraRoom: CustomStringConvertible, Hashable, Decodable {
    var name: String?
    var id: Int? // swiftlint:disable:this variable_name

    private enum CodingKeys: String, CodingKey {
        case name
        case id // swiftlint:disable:this variable_name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try? container.decode(Int.self, forKey: .id)
        self.name = try? container.decode(String.self, forKey: .name)
    }

    static func == (lhs: VeraRoom, rhs: VeraRoom) -> Bool {
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

    var hashValue: Int {
        // swiftlint:disable implicit_getter
        get {
            if self.id == nil {
                return 0
            }
            return self.id!
        }
        // swiftlint:enable implicit_getter
    }
}
