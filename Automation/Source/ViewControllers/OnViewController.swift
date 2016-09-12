//
//  OnViewController.swift
//  Automation
//
//  Created by Scott Gruby on 10/22/14.
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


class OnViewController: UICollectionViewController {
    var devices: [VeraDevice]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(OnViewController.unitInfoUpdated(_:)), name: NSNotification.Name(rawValue: VeraUnitInfoUpdated), object: nil)
        
        self.loadOnDevices()
    }

    func unitInfoUpdated(_ notification: Notification) {
        self.loadOnDevices()
    }
    
    func loadOnDevices () {
        var devices = [VeraDevice]()
        if let roomsWithSwitches = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: VeraDevice.Category.switch, VeraDevice.Category.dimmableLight) {
            for room in roomsWithSwitches {
                if let roomDevices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room: room, showExcluded: false, categories: VeraDevice.Category.switch, VeraDevice.Category.dimmableLight) {
                    for device in roomDevices {
                        if let status = device.status {
                            if status == 1 {
                                devices.append(device)
                            }
                        }
                    }
                }
            }
        }
        
        self.devices = devices
        
        self.collectionView!.reloadData()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.devices != nil {
            return self.devices!.count
        }
        
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OnCellIdentifier", for: indexPath) as! OnDeviceCell
        
        if (indexPath as NSIndexPath).row < self.devices?.count {
            let device = self.devices![(indexPath as NSIndexPath).row]
            cell.device = device
            cell.setup()
        }
        
        return cell as UICollectionViewCell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row < self.devices?.count {
            let device = self.devices![(indexPath as NSIndexPath).row]
            
            AppDelegate.appDelegate().veraAPI.setDeviceStatusWithNotification(device, newDeviceStatus: 0, newDeviceLevel: nil)
        }
    }
}
