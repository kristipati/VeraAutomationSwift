//
//  VeraUIExtension.swift
//  Automation
//
//  Created by Scott Gruby on 11/4/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

extension VeraAPI {
    public func setDeviceStatusWithNotification(_ device: VeraDevice, newDeviceStatus: Int?, newDeviceLevel: Int?) -> Void {
        
        var notificationText = ""
        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }
        
        if let status = newDeviceStatus {
            if status == 0 {
                notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_MESSAGE_OFF_%@", comment: "") as NSString, deviceName) as String
            } else {
                notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_MESSAGE_ON_%@", comment: "") as NSString, deviceName) as String
            }
        } else if let level = newDeviceLevel {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_MESSAGE_LEVEL_%@_%ld", comment: "") as NSString, deviceName, level) as String
        }

        AppDelegate.appDelegate().showMessageWithTitle(notificationText)
        
        self.setDeviceStatus(device, newDeviceStatus: newDeviceStatus, newDeviceLevel: newDeviceLevel)
    }
   
    public func runSceneWithNotification(_ scene: VeraScene) {
        var sceneName = ""
        if scene.name != nil {
            sceneName = scene.name!
        }
        
        let notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_RUN_SCENE_MESSAGE_%@", comment: "") as NSString, sceneName) as String
        AppDelegate.appDelegate().showMessageWithTitle(notificationText)
        
        self.runScene(scene)
    }
    
    public func setAudioPowerWithNotification(_ device: VeraDevice, on: Bool) {
        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }
        
        var notificationText = ""
        
        if on == false {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_MESSAGE_OFF_%@", comment: "") as NSString, deviceName) as String
        } else {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_MESSAGE_ON_%@", comment: "") as NSString, deviceName) as String
        }
        
        AppDelegate.appDelegate().showMessageWithTitle(notificationText)
        
        self.setAudioPower(device, on: on)
    }

    public func changeAudioVolumeWithNotification(_ device: VeraDevice, increase: Bool) {
        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }
        
        var notificationText = ""
        
        if increase == false {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_VOLUME_DOWN_%@", comment: "") as NSString, deviceName) as String
        } else {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_VOLUME_UP_%@", comment: "") as NSString, deviceName) as String
        }
        
        AppDelegate.appDelegate().showMessageWithTitle(notificationText)
        
        self.changeAudioVolume(device, increase: increase)
    }

    public func setAudioInputWithNotification(_ device: VeraDevice, input: Int) {
        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }
        
        var notificationText = ""
        
        notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_INPUT_%@_%d", comment: "") as NSString, deviceName as String, input) as String

        AppDelegate.appDelegate().showMessageWithTitle(notificationText)
        
        self.setAudioInput(device, input: input)
    }


    public func setLockStateWithNotification(_ device: VeraDevice, locked: Bool) {
        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }
        
        var notificationText = ""
        
        if locked == true {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_LOCKING_%@", comment: "") as NSString, deviceName) as String
        } else {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_UNLOCKING_%@", comment: "") as NSString, deviceName) as String
        }
        
        AppDelegate.appDelegate().showMessageWithTitle(notificationText)
        
        self.setLockState(device, locked: locked)
    }
    
    public func changeHVACWithNotification(_ device: VeraDevice, fanMode: VeraDevice.FanMode?, hvacMode: VeraDevice.HVACMode?, coolTemp: Int?, heatTemp: Int?) {
        
        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }

        var notificationText = ""

        if let mode = fanMode {
            switch mode {
                case .auto:
                    notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_FAN_MODE_AUTO_%@", comment: "") as NSString, deviceName) as String
                case .on:
                    notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_FAN_MODE_ON_%@", comment: "") as NSString, deviceName) as String
            }
        }
        
        if let mode = hvacMode {
            switch mode {
                case .auto:
                    notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_HVAC_AUTO_%@", comment: "") as NSString, deviceName) as String
            case .off:
                notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_HVAC_OFF_%@", comment: "") as NSString, deviceName) as String
            case .heat:
                notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_HVAC_HEAT_%@", comment: "") as NSString, deviceName) as String
            case .cool:
                notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_HVAC_COOL_%@", comment: "") as NSString, deviceName) as String
            }
        }
        
        if let temp = coolTemp {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_COOL_TEMPERATURE_%@_%d", comment: "") as NSString, deviceName, temp) as String
        }
        
        if let temp = heatTemp {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_HEAT_TEMPERATURE_%@_%d", comment: "") as NSString, deviceName, temp) as String
        }
        
        AppDelegate.appDelegate().showMessageWithTitle(notificationText)

        self.changeHVAC(device, fanMode: fanMode, hvacMode: hvacMode, coolTemp: coolTemp, heatTemp: heatTemp)
    }

}
