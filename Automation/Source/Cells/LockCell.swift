//
//  LockCell.swift
//  Automation
//
//  Created by Scott Gruby on 11/9/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera

class LockCell: BaseCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    var device: VeraDevice?
    var delegate: LockProtocol?
    
    override func setup() {
        super.setup()
        if let deviceName = self.device?.name {
            self.titleLabel.text = deviceName
        }
        
//        Swell.info("Lock info \(self.device)")
        
        if let locked = self.device?.locked {
            if locked == true {
                self.statusLabel.text = NSLocalizedString("LOCKED_LABEL", comment: "")
            } else {
                self.statusLabel.text = NSLocalizedString("UNLOCKED_LABEL", comment: "")
            }
        } else {
            self.statusLabel.text = nil
        }
    }

    @IBAction func lockAction(_ sender: AnyObject) {
        if let device = self.device {
            if let delegate = self.delegate {
                delegate.setDeviceLocked(device, locked: true)
            }
        }
    }
    @IBAction func unlockAction(_ sender: AnyObject) {
        if let device = self.device {
            if let delegate = self.delegate {
                delegate.setDeviceLocked(device, locked: false)
            }
        }
    }
}
