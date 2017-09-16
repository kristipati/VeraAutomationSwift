//
//  AudioCell.swift
//  Automation
//
//  Created by Scott Gruby on 11/9/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

class AudioCell: BaseCell {
    @IBOutlet weak var decreaseVolumeButton: UIButton!
    @IBOutlet weak var increaseVolumeButton: UIButton!
    @IBOutlet weak var server1Button: UIButton!
    @IBOutlet weak var server2Button: UIButton!
    @IBOutlet weak var server3Button: UIButton!

    @IBOutlet weak var titleLabel: UILabel!

    @IBAction func turnOff(_ sender: AnyObject) {
        if let device = device {
            delegate?.setDevicePower(device, turnOn: false)
        }
    }

    @IBAction func turnOn(_ sender: AnyObject) {
        if let device = self.device {
            delegate?.setDevicePower(device, turnOn: true)
        }
    }

    @IBAction func decreaseVolume(_ sender: AnyObject) {
        if let device = self.device {
            delegate?.changeDeviceVolume(device, increase: false)
        }
    }

    @IBAction func increaseVolume(_ sender: AnyObject) {
        if let device = self.device {
            delegate?.changeDeviceVolume(device, increase: true)
        }
    }

    @IBAction func servver1Action(_ sender: AnyObject) {
        if let device = self.device {
            delegate?.setDeviceServer(device, server: 1)
        }
    }

    @IBAction func server2Action(_ sender: AnyObject) {
        if let device = self.device {
            delegate?.setDeviceServer(device, server: 2)
        }
    }

    @IBAction func server3Action(_ sender: AnyObject) {
        if let device = self.device {
            delegate?.setDeviceServer(device, server: 3)
        }
    }

    override func setup() {
        super.setup()
        if let device = device {
            titleLabel.text = device.name
            if let parentID = device.parentID {
                decreaseVolumeButton.isHidden = (parentID == 0)
                increaseVolumeButton.isHidden = (parentID == 0)
                server1Button.isHidden = (parentID == 0)
                server2Button.isHidden = (parentID == 0)
                server3Button.isHidden = (parentID == 0)
            }
        }
    }
}
