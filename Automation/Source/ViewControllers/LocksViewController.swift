//
//  LocksViewController.swift
//  Automation
//
//  Created by Scott Gruby on 10/22/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

protocol LockProtocol {
    func setDeviceLocked(_ device: VeraDevice, locked: Bool)
}

class LocksViewController: UICollectionViewController, LockProtocol {
    var devices: [VeraDevice]?

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(LocksViewController.unitInfoUpdated(_:)), name: NSNotification.Name(rawValue: VeraUnitInfoUpdated), object: nil)

        loadLockDevices()
    }

    func unitInfoUpdated(_ notification: Notification) {
        loadLockDevices()
    }

    func loadLockDevices () {
        var newDevices = [VeraDevice]()
        if let roomsWithLocks = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: VeraDevice.Category.lock) {
            for room in roomsWithLocks {
                if let roomDevices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room: room, showExcluded: false, categories: VeraDevice.Category.lock) {
                        for device in roomDevices {
                            newDevices.append(device)
                        }
                }
            }
        }

        devices = newDevices

        collectionView!.reloadData()
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return devices?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // swiftlint:disable force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LockCell", for: indexPath) as! LockCell
        // swiftlint:enable force_cast

        if let devices = devices, indexPath.row < devices.count {
            let device = devices[indexPath.row]
            cell.device = device
            cell.delegate = self
            cell.setup()
        }

        return cell as UICollectionViewCell
    }

    func setDeviceLocked(_ device: VeraDevice, locked: Bool) {
        AppDelegate.appDelegate().veraAPI.setLockStateWithNotification(device, locked:locked)
    }
}
