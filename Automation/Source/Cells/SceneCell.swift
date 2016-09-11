//
//  SceneCell.swift
//  Automation
//
//  Created by Scott Gruby on 11/7/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

class SceneCell: BaseCell {

    var scene: VeraScene?

    @IBOutlet weak var titleLabel: UILabel!
    
    override func setup() {
        super.setup()
        if self.scene != nil {
            self.titleLabel.text = self.scene?.name
        }
    }

}
