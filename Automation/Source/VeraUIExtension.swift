//
//  VeraUIExtension.swift
//  Automation
//
//  Created by Scott Gruby on 11/4/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera

extension VeraAPI {
    public func setDeviceStatusWithNotification(device: Device, newDeviceStatus: Int?, newDeviceLevel: Int?, completionHandler:(NSError?)->Void) -> Void {
        
        var notificationText = ""
        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }
        
        if let status = newDeviceStatus {
            if status == 0 {
                notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_MESSAGE_OFF_%@", comment: ""), deviceName)
            } else {
                notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_MESSAGE_ON_%@", comment: ""), deviceName)
            }
        } else if let level = newDeviceLevel {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_MESSAGE_LEVEL_%@_%ld", comment: ""), deviceName, level)
        }
        
        
        
        Swell.info("Changing status \(notificationText)")
        
        AppDelegate.appDelegate().showMessageWithTitle(notificationText)
        
        self.setDeviceStatus(device, newDeviceStatus: newDeviceStatus, newDeviceLevel: newDeviceLevel, completionHandler: completionHandler)
    }
   
    public func runSceneWithNotification(scene: Scene, completionHandler:(NSError?)->Void) -> Void {
        var sceneName = ""
        if scene.name != nil {
            sceneName = scene.name!
        }
        
        let notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_RUN_SCENE_MESSAGE_%@", comment: ""), sceneName)
        
        Swell.info("Running scene: \(notificationText)")
        
        AppDelegate.appDelegate().showMessageWithTitle(notificationText)
        
        self.runScene(scene, completionHandler: completionHandler)
    }
    
    public func setAudioPowerWithNotification(device: Device, on: Bool, completionHandler:(NSError?)->Void) -> Void {
        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }
        
        var notificationText = ""
        
        if on == false {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_MESSAGE_OFF_%@", comment: ""), deviceName)
        } else {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_MESSAGE_ON_%@", comment: ""), deviceName)
        }
        
        AppDelegate.appDelegate().showMessageWithTitle(notificationText)
        
        self.setAudioPower(device, on: on, completionHandler: completionHandler)
    }

    public func changeAudioVolumeWithNotification(device: Device, increase: Bool, completionHandler:(NSError?)->Void) -> Void {
        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }
        
        var notificationText = ""
        
        if increase == false {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_VOLUME_DOWN_%@", comment: ""), deviceName)
        } else {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_VOLUME_UP_%@", comment: ""), deviceName)
        }
        
        AppDelegate.appDelegate().showMessageWithTitle(notificationText)
        
        self.changeAudioVolume(device, increase: increase, completionHandler: completionHandler)
    }

    public func setAudioInputWithNotification(device: Device, input: Int, completionHandler:(NSError?)->Void) -> Void {
        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }
        
        var notificationText = ""
        
        notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_INPUT_%@_%d", comment: ""), deviceName, input)

        AppDelegate.appDelegate().showMessageWithTitle(notificationText)
        
        self.setAudioInput(device, input: input, completionHandler: completionHandler)
    }


    public func setLockStateWithNotification(device: Device, locked: Bool, completionHandler:(NSError?)->Void) -> Void {
        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }
        
        var notificationText = ""
        
        if locked == true {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_LOCKING_%@", comment: ""), deviceName)
        } else {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_UNLOCKING_%@", comment: ""), deviceName)
        }
        
        AppDelegate.appDelegate().showMessageWithTitle(notificationText)
        
        self.setLockState(device, locked: locked, completionHandler: completionHandler)
    }
    
    public func changeHVACWithNotification(device: Device, fanMode: Device.FanMode?, hvacMode: Device.HVACMode?, coolTemp: Int?, heatTemp: Int?, completionHandler:(NSError?)->Void) -> Void {
        
        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }

        var notificationText = ""

        if let mode = fanMode {
            switch mode {
                case .Auto:
                    notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_FAN_MODE_AUTO_%@", comment: ""), deviceName)
                case .On:
                    notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_FAN_MODE_ON_%@", comment: ""), deviceName)
            }
        }
        
        if let mode = hvacMode {
            switch mode {
                case .Auto:
                    notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_HVAC_AUTO_%@", comment: ""), deviceName)
            case .Off:
                notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_HVAC_OFF_%@", comment: ""), deviceName)
            case .Heat:
                notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_HVAC_HEAT_%@", comment: ""), deviceName)
            case .Cool:
                notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_HVAC_COOL_%@", comment: ""), deviceName)
            }
        }
        
        if let temp = coolTemp {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_COOL_TEMPERATURE_%@_%d", comment: ""), deviceName, temp)
        }
        
        if let temp = heatTemp {
            notificationText = NSString.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_HEAT_TEMPERATURE_%@_%d", comment: ""), deviceName, temp)
        }
        
        AppDelegate.appDelegate().showMessageWithTitle(notificationText)

        self.changeHVAC(device, fanMode: fanMode, hvacMode: hvacMode, coolTemp: coolTemp, heatTemp: heatTemp, completionHandler:completionHandler)
    }

}
