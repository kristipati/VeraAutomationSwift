//
//  ThermostatCell.swift
//  Automation
//
//  Created by Scott Gruby on 11/9/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

class ThermostatCell: BaseCell {

    @IBOutlet weak var currentTemperature: UILabel!
    @IBOutlet weak var fanSegmentedControl: UISegmentedControl!
    @IBOutlet weak var hvacSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var coolStepper: UIStepper!
    
    @IBOutlet weak var heatStepper: UIStepper!
    @IBOutlet weak var heatSetLabel: UILabel!
    @IBOutlet weak var coolSetLabel: UILabel!

    var delegate: ThermostatProtocol?
    var device: VeraDevice?

    override func setup() {
        super.setup()
        if let device = device {
            if let temp = device.temperature {
                currentTemperature.text = "\(temp)"
            } else {
                currentTemperature.text = nil
            }
            
            if let fanMode = device.fanMode {
                switch fanMode {
                    case .auto:
                        fanSegmentedControl.selectedSegmentIndex = 0
                    
                    case .on:
                        fanSegmentedControl.selectedSegmentIndex = 1
                }
            }

            if let hvacMode = device.hvacMode {
                switch hvacMode {
                case .auto:
                    hvacSegmentedControl.selectedSegmentIndex = 1
                    
                case .off:
                    hvacSegmentedControl.selectedSegmentIndex = 0
                case .cool:
                    hvacSegmentedControl.selectedSegmentIndex = 2
                case .heat:
                    hvacSegmentedControl.selectedSegmentIndex = 3
                }
            }
            
            if let coolSP = device.coolTemperatureSetPoint {
                coolSetLabel.text = "\(coolSP)"
                coolStepper.value = Double(coolSP)
            } else {
                coolSetLabel.text = nil
                coolStepper.value = 75
            }

            if let heatSP = device.heatTemperatureSetPoint {
                heatSetLabel.text = "\(heatSP)"
                heatStepper.value = Double(heatSP)
            } else {
                heatSetLabel.text = nil
                heatStepper.value = 75
            }
        }
    }

    @IBAction func hvacStateChanged(_ sender: AnyObject) {
        var hvacMode: VeraDevice.HVACMode = .auto
        if hvacSegmentedControl.selectedSegmentIndex == 0 {
            hvacMode = .off
        }
        else if hvacSegmentedControl.selectedSegmentIndex == 2 {
            hvacMode = .cool
        }
        else if hvacSegmentedControl.selectedSegmentIndex == 3 {
            hvacMode = .heat
        }
        
        if let  device = device, let delegate = delegate {
            delegate.changeHVAC(device, fanMode: nil, hvacMode: hvacMode, coolTemp: nil, heatTemp: nil)
        }
    }
    
    @IBAction func fanChanged(_ sender: AnyObject) {
        var fanMode: VeraDevice.FanMode = .auto
        if fanSegmentedControl.selectedSegmentIndex == 1 {
            fanMode = .on
        }

        if let  device = device, let delegate = delegate {
            delegate.changeHVAC(device, fanMode: fanMode, hvacMode: nil, coolTemp: nil, heatTemp: nil)
        }
    }
    
    @IBAction func heatStepperChanged(_ sender: AnyObject) {
        if let  device = device, let delegate = delegate {
            delegate.changeHVAC(device, fanMode: nil, hvacMode: nil, coolTemp: nil, heatTemp: Int(self.heatStepper.value))
        }
    }
    
    @IBAction func coolStepperChanged(_ sender: AnyObject) {
        if let  device = device, let delegate = delegate {
            delegate.changeHVAC(device, fanMode: nil, hvacMode: nil, coolTemp: Int(self.coolStepper.value), heatTemp: nil)
        }
    }
}
