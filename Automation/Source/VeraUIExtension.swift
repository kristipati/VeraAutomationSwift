//
//  VeraUIExtension.swift
//  Automation
//
//  Created by Scott Gruby on 11/4/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

extension VeraAPI {
    func setDeviceStatusWithNotification(_ device: VeraDevice, newDeviceStatus: Int?, newDeviceLevel: Int?) {

        var notificationText = ""
        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }

        if let status = newDeviceStatus {
            if status == 0 {
                notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_MESSAGE_OFF_%@", comment: ""), deviceName)
            } else {
                notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_MESSAGE_ON_%@", comment: ""), deviceName)
            }
        } else if let level = newDeviceLevel {
            notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_MESSAGE_LEVEL_%@_%ld", comment: ""), deviceName, level)
        }

        AppDelegate.appDelegate().showMessageWithTitle(title: notificationText)

        setDeviceStatus(device: device, newDeviceStatus: newDeviceStatus, newDeviceLevel: newDeviceLevel)
    }

    func runSceneWithNotification(_ scene: VeraScene) {
        var sceneName = ""
        if scene.name != nil {
            sceneName = scene.name!
        }

        let notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_RUN_SCENE_MESSAGE_%@", comment: ""), sceneName)
        AppDelegate.appDelegate().showMessageWithTitle(title: notificationText)

        runScene(scene: scene)
    }

    func setAudioPowerWithNotification(_ device: VeraDevice, on turnOn: Bool) {
        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }

        var notificationText = ""

        if turnOn == false {
            notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_MESSAGE_OFF_%@", comment: ""), deviceName)
        } else {
            notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_MESSAGE_ON_%@", comment: ""), deviceName)
        }

        AppDelegate.appDelegate().showMessageWithTitle(title: notificationText)

        setAudioPower(device: device, on: turnOn)
    }

    func changeAudioVolumeWithNotification(_ device: VeraDevice, increase: Bool) {
        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }

        var notificationText = ""

        if increase == false {
            notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_VOLUME_DOWN_%@", comment: ""), deviceName)
        } else {
            notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_VOLUME_UP_%@", comment: ""), deviceName)
        }

        AppDelegate.appDelegate().showMessageWithTitle(title: notificationText)

        changeAudioVolume(device: device, increase: increase)
    }

    func setAudioInputWithNotification(_ device: VeraDevice, input: Int) {
        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }

        var notificationText = ""

        notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_INPUT_%@_%d", comment: ""), deviceName, input)

        AppDelegate.appDelegate().showMessageWithTitle(title: notificationText)

        setAudioInput(device: device, input: input)
    }

    func setLockStateWithNotification(_ device: VeraDevice, locked: Bool) {
        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }

        var notificationText = ""

        if locked == true {
            notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_LOCKING_%@", comment: ""), deviceName)
        } else {
            notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_UNLOCKING_%@", comment: ""), deviceName)
        }

        AppDelegate.appDelegate().showMessageWithTitle(title: notificationText)

        setLockState(device: device, locked: locked)
    }

    func changeHVACWithNotification(_ device: VeraDevice, fanMode: VeraDevice.FanMode?, hvacMode: VeraDevice.HVACMode?, coolTemp: Int?, heatTemp: Int?) {

        var deviceName = ""
        if device.name != nil {
            deviceName = device.name!
        }

        var notificationText = ""

        if let mode = fanMode {
            switch mode {
                case .auto:
                    notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_FAN_MODE_AUTO_%@", comment: ""), deviceName)
                case .on:
                    notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_FAN_MODE_ON_%@", comment: ""), deviceName)
            }
        }

        if let mode = hvacMode {
            switch mode {
                case .auto:
                    notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_HVAC_AUTO_%@", comment: ""), deviceName)
            case .off:
                notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_HVAC_OFF_%@", comment: ""), deviceName)
            case .heat:
                notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_HVAC_HEAT_%@", comment: ""), deviceName)
            case .cool:
                notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_HVAC_COOL_%@", comment: ""), deviceName)
            }
        }

        if let temp = coolTemp {
            notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_COOL_TEMPERATURE_%@_%d", comment: ""), deviceName, temp)
        }

        if let temp = heatTemp {
            notificationText = String.localizedStringWithFormat(NSLocalizedString("COMMAND_SENT_HEAT_TEMPERATURE_%@_%d", comment: ""), deviceName, temp)
        }

        AppDelegate.appDelegate().showMessageWithTitle(title: notificationText)

        changeHVAC(device: device, fanMode: fanMode, hvacMode: hvacMode, coolTemp: coolTemp, heatTemp: heatTemp)
    }

}
