//
//  SwitchesViewController.swift
//  Automation
//
//  Created by Scott Gruby on 11/2/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

protocol SwitchProtocol {
    func changeDeviceLevel(_ device: VeraDevice, level: Int)
}

class SwitchesViewController: UICollectionViewController, SwitchProtocol {
    var room: VeraRoom?
    var devices: [VeraDevice]?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let room = room {
            devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room: room, categories: .switch, .dimmableLight)
            title = room.name
        }

        NotificationCenter.default.addObserver(self, selector: #selector(SwitchesViewController.unitInfoUpdated(_:)), name: NSNotification.Name(rawValue: VeraUnitInfoUpdated), object: nil)
    }

    func unitInfoUpdated(_ notification: Notification) {
        var fullload = false
        if let info = (notification as NSNotification).userInfo as? Dictionary<String, AnyObject> {
            if let tempFullLoad = info[VeraUnitInfoFullLoad] as? Bool {
                fullload = tempFullLoad
            }
        }

        if fullload == true {
            room = nil
            devices = nil
            title = nil
            navigationItem.leftBarButtonItem = nil
        }
        collectionView!.reloadData()
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return devices?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // swiftlint:disable force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DeviceCell", for: indexPath) as! DeviceCell
        // swiftlint:enable force_cast

        if let devices = devices, indexPath.row < devices.count {
            let device = devices[indexPath.row]
            cell.device = device
            cell.delegate = self
            cell.setup()
        }

        return cell as UICollectionViewCell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let devices = devices, indexPath.row < devices.count {
            let device = devices[indexPath.row]
            var newStatus = 0
            if let status = device.status {
                if status == 0 {
                    newStatus = 1
                }
            }

            AppDelegate.appDelegate().veraAPI.setDeviceStatusWithNotification(device, newDeviceStatus: newStatus, newDeviceLevel: nil)
        }
    }

    func changeDeviceLevel(_ device: VeraDevice, level: Int) {
        AppDelegate.appDelegate().veraAPI.setDeviceStatusWithNotification(device, newDeviceStatus: nil, newDeviceLevel: level)
    }
}
