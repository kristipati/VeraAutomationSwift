//
//  AudioViewController.swift
//  Automation
//
//  Created by Scott Gruby on 11/2/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit


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

        if let room = room {
            devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room: room, showExcluded: false, categories: .audio)
            title = room.name
        }

        NotificationCenter.default.addObserver(self, selector: #selector(AudioViewController.unitInfoUpdated(_:)), name: NSNotification.Name(rawValue: VeraUnitInfoUpdated), object: nil)
    }
    
    func unitInfoUpdated(_ notification: Notification) {
        var fullload = false
        if let info = (notification as NSNotification).userInfo as? Dictionary<String, AnyObject>, let tempFullLoad = info[VeraUnitInfoFullLoad] as? Bool  {
            fullload = tempFullLoad
        }
        
        if fullload == true {
            room = nil
            devices = nil
            title = nil
            navigationItem.leftBarButtonItem = nil
        }
        
        collectionView!.reloadData()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return devices?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AudioDeviceCell", for: indexPath) as! AudioCell
        
        if let devices = devices, indexPath.row < devices.count {
            let device = devices[indexPath.row]
            cell.device = device
            cell.delegate = self
            cell.setup()
        }
        
        return cell
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
