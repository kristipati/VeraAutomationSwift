//
//  SceneCell.swift
//  Automation
//
//  Created by Scott Gruby on 11/7/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

class SceneCell: BaseCell {

    @IBOutlet weak var titleLabel: UILabel!

    override func setup() {
        super.setup()
        titleLabel.text = scene?.name
    }

}
