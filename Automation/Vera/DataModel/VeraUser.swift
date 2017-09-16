//
//  User.swift
//  Automation
//
//  Created by Scott Gruby on 10/5/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import Foundation

class VeraUser: Decodable {
    var units: [VeraUnit]?

    private enum CodingKeys: String, CodingKey {
        case units
        case devices = "Devices"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.units = try? container.decode([VeraUnit].self, forKey: .units)
        if self.units == nil {
            self.units = try? container.decode([VeraUnit].self, forKey: .devices)
        }
    }
}
