//
//  LocksViewController.swift
//  Automation
//
//  Created by Scott Gruby on 10/22/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera
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


protocol LockProtocol {
    func setDeviceLocked(_ device:Device, locked: Bool)
}

class LocksViewController: UICollectionViewController, LockProtocol {
    var devices: [Device]?

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(LocksViewController.unitInfoUpdated(_:)), name: NSNotification.Name(rawValue: Vera.VeraUnitInfoUpdated), object: nil)
        
        self.loadLockDevices()
    }
    
    func unitInfoUpdated(_ notification: Notification) {
        self.loadLockDevices()
    }
    
    func loadLockDevices () {
        var devices = [Device]()
        if let roomsWithLocks = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: Vera.Device.Category.lock) {
            for room in roomsWithLocks {
                if let roomDevices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room, showExcluded: false, categories: Vera.Device.Category.lock) {
                        for device in roomDevices {
                            devices.append(device)
                        }
                }
            }
        }
        
        self.devices = devices
        
        self.collectionView!.reloadData()
    }


    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.devices != nil {
            return self.devices!.count
        }
        
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LockCell", for: indexPath) as! LockCell
        
        if (indexPath as NSIndexPath).row < self.devices?.count {
            let device = self.devices![(indexPath as NSIndexPath).row]
            cell.device = device
            cell.delegate = self
            cell.setup()
        }
        
        return cell as UICollectionViewCell
    }
    
    func setDeviceLocked(_ device:Device, locked: Bool) {
        AppDelegate.appDelegate().veraAPI.setLockStateWithNotification(device, locked:locked)
    }


}
