//
//  AudioViewController.swift
//  Automation
//
//  Created by Scott Gruby on 11/2/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera

protocol AudioProtocol {
    func setDevicePower(device:Device, turnOn: Bool)
    func changeDeviceVolume(device:Device, increase: Bool)
    func setDeviceServer(device:Device, server: Int)
}


class AudioViewController: UICollectionViewController, AudioProtocol {
    var room: Room?
    var devices: [Device]?

    override func viewDidLoad() {
        super.viewDidLoad()

        if self.room != nil {
            self.devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(self.room!, showExcluded: false, categories: .Audio)
            self.title = self.room?.name
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "unitInfoUpdated:", name: Vera.VeraUnitInfoUpdated, object: nil)
    }
    
    func unitInfoUpdated(notification: NSNotification) {
        if let unit = AppDelegate.appDelegate().veraAPI.getVeraUnit() {
            if unit.fullload == true {
                self.room = nil
                self.devices = nil
                self.title = nil
                self.navigationItem.leftBarButtonItem = nil
            }
        }
        self.collectionView.reloadData()
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let devices = self.devices {
            return devices.count
        }
        
        return 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AudioDeviceCell", forIndexPath: indexPath) as AudioCell
        
        if indexPath.row < self.devices?.count {
            let device = self.devices![indexPath.row]
            cell.device = device
            cell.delegate = self
            cell.setup()
        }
        
        return cell as UICollectionViewCell
    }

    func setDevicePower(device:Device, turnOn: Bool) {
        AppDelegate.appDelegate().veraAPI.setAudioPowerWithNotification(device, on:turnOn, completionHandler: { (error: NSError?) -> Void in
        })
    }
    
    func changeDeviceVolume(device:Device, increase: Bool) {
        AppDelegate.appDelegate().veraAPI.changeAudioVolumeWithNotification(device, increase:increase, completionHandler: { (error: NSError?) -> Void in
        })
    }
    
    func setDeviceServer(device:Device, server: Int) {
        AppDelegate.appDelegate().veraAPI.setAudioInputWithNotification(device, input:server, completionHandler: { (error: NSError?) -> Void in
        })
    }
}
