//
//  OnDeviceCell.swift
//  Automation
//
//  Created by Scott Gruby on 11/9/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera

class OnDeviceCell: BaseCell {

    @IBOutlet weak var titleLabel: UILabel!
    var device: Device?

    override func setup() {
        super.setup()
        if self.device != nil {
            self.titleLabel.text = self.device?.name
        }
    }
}
