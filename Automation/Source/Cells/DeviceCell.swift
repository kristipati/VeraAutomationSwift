//
//  DeviceCell.swift
//  Automation
//
//  Created by Scott Gruby on 11/2/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

class DeviceCell: BaseCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    
    var device: VeraDevice?
    var delegate: SwitchProtocol?
    
    @IBAction func sliderTouchUpAction(_ sender: UISlider) {
        if let delegate = delegate, let device = device {
            delegate.changeDeviceLevel(device, level: Int(sender.value))
        }
    }
    
    override func setup() {
        super.setup()
        if let device = device {
            titleLabel.text = device.name
            if let status = device.status {
                if status == 0 {
                    statusLabel.text = NSLocalizedString("OFF_LABEL", comment: "")
                } else if status == 1 {
                    statusLabel.text = NSLocalizedString("ON_LABEL", comment: "")
                }
            }
            
            if let cat = device.category {
                switch cat {
                case .dimmableLight:
                    slider.isHidden = false
                    if let level = device.level {
                        slider.value = Float(level)
                    }
                case .switch:
                    slider.isHidden = true
                default:
                    slider.isHidden = true
                }
            }
        }
    }
}
