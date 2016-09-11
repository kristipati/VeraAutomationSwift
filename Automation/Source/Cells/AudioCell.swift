//
//  AudioCell.swift
//  Automation
//
//  Created by Scott Gruby on 11/9/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

class AudioCell: BaseCell {

    var device: VeraDevice?
    var delegate: AudioProtocol?

    @IBOutlet weak var decreaseVolumeButton: UIButton!
    @IBOutlet weak var increaseVolumeButton: UIButton!
    @IBOutlet weak var server1Button: UIButton!
    @IBOutlet weak var server2Button: UIButton!
    @IBOutlet weak var server3Button: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBAction func turnOff(_ sender: AnyObject) {
        if let device = self.device {
            if self.delegate != nil {
                self.delegate?.setDevicePower(device, turnOn: false)
            }
        }
    }
    
    @IBAction func turnOn(_ sender: AnyObject) {
        if let device = self.device {
            if self.delegate != nil {
                self.delegate?.setDevicePower(device, turnOn: true)
            }
        }
    }

    @IBAction func decreaseVolume(_ sender: AnyObject) {
        if let device = self.device {
            if self.delegate != nil {
                self.delegate?.changeDeviceVolume(device, increase: false)
            }
        }
    }

    @IBAction func increaseVolume(_ sender: AnyObject) {
        if let device = self.device {
            if self.delegate != nil {
                self.delegate?.changeDeviceVolume(device, increase: true)
            }
        }
    }

    @IBAction func servver1Action(_ sender: AnyObject) {
        if let device = self.device {
            if self.delegate != nil {
                self.delegate?.setDeviceServer(device, server: 1)
            }
        }
    }

    @IBAction func server2Action(_ sender: AnyObject) {
        if let device = self.device {
            if self.delegate != nil {
                self.delegate?.setDeviceServer(device, server: 2)
            }
        }
    }

    @IBAction func server3Action(_ sender: AnyObject) {
        if let device = self.device {
            if self.delegate != nil {
                self.delegate?.setDeviceServer(device, server: 3)
            }
        }
    }
    
    override func setup() {
        super.setup()
        if self.device != nil {
            self.titleLabel.text = self.device!.name
            if let parentID = self.device?.parentID {
                self.decreaseVolumeButton.isHidden = (parentID == 0)
                self.increaseVolumeButton.isHidden = (parentID == 0)
                self.server1Button.isHidden = (parentID == 0)
                self.server2Button.isHidden = (parentID == 0)
                self.server3Button.isHidden = (parentID == 0)
            }
        }
    }
}
