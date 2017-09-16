//
//  RoomTableViewCell.swift
//  Automation
//
//  Created by Scott Gruby on 9/15/17.
//  Copyright © 2017 Gruby Solutions. All rights reserved.
//

import UIKit

class RoomTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!

    var room: String? {
        didSet {
            nameLabel.text = room
        }
    }
}
