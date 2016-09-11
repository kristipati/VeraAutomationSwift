//
//  DeviceCell.swift
//  Automation
//
//  Created by Scott Gruby on 11/2/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera

class DeviceCell: BaseCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    
    var device: VeraDevice?
    var delegate: SwitchProtocol?
    
    @IBAction func sliderTouchUpAction(_ sender: UISlider) {
        if let delegate = self.delegate {
            delegate.changeDeviceLevel(self.device!, level: Int(sender.value))
        }
    }
    
    override func setup() {
        super.setup()
        if self.device != nil {
            self.titleLabel.text = self.device?.name
            if let status = self.device?.status {
                if status == 0 {
                    self.statusLabel.text = NSLocalizedString("OFF_LABEL", comment: "")
                } else if status == 1 {
                    self.statusLabel.text = NSLocalizedString("ON_LABEL", comment: "")
                }
            }
            
            if let cat = self.device?.category {
                switch cat {
                case .dimmableLight:
                    self.slider.isHidden = false
                    if let level = self.device?.level {
                        self.slider.value = Float(level)
                    }
                case .switch:
                    self.slider.isHidden = true
                default:
                    self.slider.isHidden = true
                }
            }
        }
    }
}
