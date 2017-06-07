//
//  OnViewController.swift
//  Automation
//
//  Created by Scott Gruby on 10/22/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

class OnViewController: UICollectionViewController {
    var devices: [VeraDevice]?

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(OnViewController.unitInfoUpdated(_:)), name: NSNotification.Name(rawValue: VeraUnitInfoUpdated), object: nil)

        loadOnDevices()
    }

    @objc func unitInfoUpdated(_ notification: Notification) {
        loadOnDevices()
    }

    func loadOnDevices () {
        var newDevices = [VeraDevice]()
        if let roomsWithSwitches = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: VeraDevice.Category.switch, VeraDevice.Category.dimmableLight) {
            for room in roomsWithSwitches {
                if let roomDevices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room: room, showExcluded: false, categories: VeraDevice.Category.switch, VeraDevice.Category.dimmableLight) {
                    for device in roomDevices {
                        if let status = device.status {
                            if status == 1 {
                                newDevices.append(device)
                            }
                        }
                    }
                }
            }
        }

        devices = newDevices

        collectionView!.reloadData()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return devices?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // swiftlint:disable force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OnCellIdentifier", for: indexPath) as! OnDeviceCell
        // swiftlint:enable force_cast

        if let devices = devices, indexPath.row < devices.count {
            let device = devices[indexPath.row]
            cell.device = device
            cell.setup()
        }

        return cell as UICollectionViewCell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let devices = devices, indexPath.row < devices.count {
            let device = devices[indexPath.row]

            AppDelegate.appDelegate().veraAPI.setDeviceStatusWithNotification(device, newDeviceStatus: 0, newDeviceLevel: nil)
        }
    }
}
