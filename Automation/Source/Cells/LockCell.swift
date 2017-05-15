//
//  LockCell.swift
//  Automation
//
//  Created by Scott Gruby on 11/9/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

class LockCell: BaseCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    var device: VeraDevice?
    weak var delegate: LockProtocol?

    override func setup() {
        super.setup()
        titleLabel.text = device?.name

        if let locked = device?.locked {
            if locked == true {
                statusLabel.text = NSLocalizedString("LOCKED_LABEL", comment: "")
            } else {
                statusLabel.text = NSLocalizedString("UNLOCKED_LABEL", comment: "")
            }
        } else {
            statusLabel.text = nil
        }
    }

    @IBAction func lockAction(_ sender: AnyObject) {
        if let device = device, let delegate = delegate {
            delegate.setDeviceLocked(device, locked: true)
        }
    }
    @IBAction func unlockAction(_ sender: AnyObject) {
        if let device = device, let delegate = delegate {
            delegate.setDeviceLocked(device, locked: false)
        }
    }
}
