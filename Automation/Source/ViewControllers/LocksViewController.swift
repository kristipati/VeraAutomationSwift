//
//  LocksViewController.swift
//  Automation
//
//  Created by Scott Gruby on 10/22/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera

protocol LockProtocol {
    func setDeviceLocked(device:Device, locked: Bool)
}

class LocksViewController: UICollectionViewController, LockProtocol {
    var devices: [Device]?

    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LocksViewController.unitInfoUpdated(_:)), name: Vera.VeraUnitInfoUpdated, object: nil)
        
        self.loadLockDevices()
    }
    
    func unitInfoUpdated(notification: NSNotification) {
        self.loadLockDevices()
    }
    
    func loadLockDevices () {
        var devices = [Device]()
        if let roomsWithLocks = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: Vera.Device.Category.Lock) {
            for room in roomsWithLocks {
                if let roomDevices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room, showExcluded: false, categories: Vera.Device.Category.Lock) {
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

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.devices != nil {
            return self.devices!.count
        }
        
        return 0
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("LockCell", forIndexPath: indexPath) as! LockCell
        
        if indexPath.row < self.devices?.count {
            let device = self.devices![indexPath.row]
            cell.device = device
            cell.delegate = self
            cell.setup()
        }
        
        return cell as UICollectionViewCell
    }
    
    func setDeviceLocked(device:Device, locked: Bool) {
        AppDelegate.appDelegate().veraAPI.setLockStateWithNotification(device, locked:locked, completionHandler: { (error: NSError?) -> Void in
            
        })
    }


}
