//
//  SwitchesViewController.swift
//  Automation
//
//  Created by Scott Gruby on 11/2/14.
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


protocol SwitchProtocol {
    func changeDeviceLevel(_ device: Device, level: Int)
}

class SwitchesViewController: UICollectionViewController, SwitchProtocol {
    var room: Room?
    var devices: [Device]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if self.room != nil {
            self.devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(self.room!, categories: .switch, .dimmableLight)
            self.title = self.room?.name
        }

        NotificationCenter.default.addObserver(self, selector: #selector(SwitchesViewController.unitInfoUpdated(_:)), name: NSNotification.Name(rawValue: Vera.VeraUnitInfoUpdated), object: nil)
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

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.devices != nil {
            return self.devices!.count
        }

        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DeviceCell", for: indexPath) as! DeviceCell
    
        if (indexPath as NSIndexPath).row < self.devices?.count {
            let device = self.devices![(indexPath as NSIndexPath).row]
            cell.device = device
            cell.delegate = self
            cell.setup()
        }
    
        return cell as UICollectionViewCell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row < self.devices?.count {
            let device = self.devices![(indexPath as NSIndexPath).row]
            var newStatus = 0
            if let status = device.status {
                if status == 0 {
                    newStatus = 1
                }
            }
            
            AppDelegate.appDelegate().veraAPI.setDeviceStatusWithNotification(device, newDeviceStatus: newStatus, newDeviceLevel: nil)
        }
    }
    
    func changeDeviceLevel(_ device: Device, level: Int) {
        AppDelegate.appDelegate().veraAPI.setDeviceStatusWithNotification(device, newDeviceStatus: nil, newDeviceLevel: level)
    }
}
