//
//  AudioViewController.swift
//  Automation
//
//  Created by Scott Gruby on 11/2/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


protocol AudioProtocol {
    func setDevicePower(_ device:VeraDevice, turnOn: Bool)
    func changeDeviceVolume(_ device:VeraDevice, increase: Bool)
    func setDeviceServer(_ device:VeraDevice, server: Int)
}


class AudioViewController: UICollectionViewController, AudioProtocol {
    var room: VeraRoom?
    var devices: [VeraDevice]?

    override func viewDidLoad() {
        super.viewDidLoad()

        if self.room != nil {
            self.devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room: self.room!, showExcluded: false, categories: .audio)
            self.title = self.room?.name
        }

        NotificationCenter.default.addObserver(self, selector: #selector(AudioViewController.unitInfoUpdated(_:)), name: NSNotification.Name(rawValue: VeraUnitInfoUpdated), object: nil)
    }
    
    func unitInfoUpdated(_ notification: Notification) {
        var fullload = false
        if let info = (notification as NSNotification).userInfo as? Dictionary<String, AnyObject> {
            if let tempFullLoad = info[VeraUnitInfoFullLoad] as? Bool {
                fullload = tempFullLoad
            }
        }
        
        if fullload == true {
            self.room = nil
            self.devices = nil
            self.title = nil
            self.navigationItem.leftBarButtonItem = nil
        }
        self.collectionView!.reloadData()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let devices = self.devices {
            return devices.count
        }
        
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AudioDeviceCell", for: indexPath) as! AudioCell
        
        if (indexPath as NSIndexPath).row < self.devices?.count {
            let device = self.devices![(indexPath as NSIndexPath).row]
            cell.device = device
            cell.delegate = self
            cell.setup()
        }
        
        return cell as UICollectionViewCell
    }

    func setDevicePower(_ device:VeraDevice, turnOn: Bool) {
        AppDelegate.appDelegate().veraAPI.setAudioPowerWithNotification(device, on:turnOn)
    }
    
    func changeDeviceVolume(_ device:VeraDevice, increase: Bool) {
        AppDelegate.appDelegate().veraAPI.changeAudioVolumeWithNotification(device, increase:increase)
    }
    
    func setDeviceServer(_ device:VeraDevice, server: Int) {
        AppDelegate.appDelegate().veraAPI.setAudioInputWithNotification(device, input:server)
    }
}
