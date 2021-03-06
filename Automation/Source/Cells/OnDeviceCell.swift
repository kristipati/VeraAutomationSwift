//
//  OnDeviceCell.swift
//  Automation
//
//  Created by Scott Gruby on 11/9/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

class OnDeviceCell: BaseCell {

    @IBOutlet weak var titleLabel: UILabel!

    override func setup() {
        super.setup()
        titleLabel.text = device?.name
    }
}
