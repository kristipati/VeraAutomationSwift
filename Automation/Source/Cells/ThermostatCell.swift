//
//  ThermostatCell.swift
//  Automation
//
//  Created by Scott Gruby on 11/9/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera

class ThermostatCell: BaseCell {

    @IBOutlet weak var currentTemperature: UILabel!
    @IBOutlet weak var fanSegmentedControl: UISegmentedControl!
    @IBOutlet weak var hvacSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var coolStepper: UIStepper!
    
    @IBOutlet weak var heatStepper: UIStepper!
    @IBOutlet weak var heatSetLabel: UILabel!
    @IBOutlet weak var coolSetLabel: UILabel!

    var delegate: ThermostatProtocol?
    var device: Device?

    override func setup() {
        super.setup()
        if let device = self.device {
            if let temp = device.temperature {
                self.currentTemperature.text = "\(temp)"
            } else {
                self.currentTemperature.text = nil
            }
            
            if let fanMode = device.fanMode {
                switch fanMode {
                    case .auto:
                        self.fanSegmentedControl.selectedSegmentIndex = 0
                    
                    case .on:
                        self.fanSegmentedControl.selectedSegmentIndex = 1
                }
            }

            if let hvacMode = device.hvacMode {
                switch hvacMode {
                case .auto:
                    self.hvacSegmentedControl.selectedSegmentIndex = 1
                    
                case .off:
                    self.hvacSegmentedControl.selectedSegmentIndex = 0
                case .cool:
                    self.hvacSegmentedControl.selectedSegmentIndex = 2
                case .heat:
                    self.hvacSegmentedControl.selectedSegmentIndex = 3
                }
            }
            
            if let coolSP = device.coolTemperatureSetPoint {
                self.coolSetLabel.text = "\(coolSP)"
                self.coolStepper.value = Double(coolSP)
            } else {
                self.coolSetLabel.text = nil
                self.coolStepper.value = 75
            }

            if let heatSP = device.heatTemperatureSetPoint {
                self.heatSetLabel.text = "\(heatSP)"
                self.heatStepper.value = Double(heatSP)
            } else {
                self.heatSetLabel.text = nil
                self.heatStepper.value = 75
            }
        }
    }

    @IBAction func hvacStateChanged(_ sender: AnyObject) {
        var hvacMode: Device.HVACMode = .auto
        if self.hvacSegmentedControl.selectedSegmentIndex == 0 {
            hvacMode = .off
        }
        else if self.hvacSegmentedControl.selectedSegmentIndex == 2 {
            hvacMode = .cool
        }
        else if self.hvacSegmentedControl.selectedSegmentIndex == 3 {
            hvacMode = .heat
        }
        
        if let  device = self.device {
            if let delegate = self.delegate {
                delegate.changeHVAC(device, fanMode: nil, hvacMode: hvacMode, coolTemp: nil, heatTemp: nil)
            }
        }
    }
    
    @IBAction func fanChanged(_ sender: AnyObject) {
        var fanMode: Device.FanMode = .auto
        if self.fanSegmentedControl.selectedSegmentIndex == 1 {
            fanMode = .on
        }

        if let  device = self.device {
            if let delegate = self.delegate {
                delegate.changeHVAC(device, fanMode: fanMode, hvacMode: nil, coolTemp: nil, heatTemp: nil)
            }
        }
    }
    
    @IBAction func heatStepperChanged(_ sender: AnyObject) {
        if let  device = self.device {
            if let delegate = self.delegate {
                delegate.changeHVAC(device, fanMode: nil, hvacMode: nil, coolTemp: nil, heatTemp: Int(self.heatStepper.value))
            }
        }
    }
    
    @IBAction func coolStepperChanged(_ sender: AnyObject) {
        if let  device = self.device {
            if let delegate = self.delegate {
                delegate.changeHVAC(device, fanMode: nil, hvacMode: nil, coolTemp: Int(self.coolStepper.value), heatTemp: nil)
            }
        }
    }
}
