//
//  OnViewController.swift
//  Automation
//
//  Created by Scott Gruby on 10/22/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera

class OnViewController: UICollectionViewController {
    var devices: [Device]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "unitInfoUpdated:", name: Vera.VeraUnitInfoUpdated, object: nil)
        
        self.loadOnDevices()
    }

    func unitInfoUpdated(notification: NSNotification) {
        self.loadOnDevices()
    }
    
    func loadOnDevices () {
        var devices = [Device]()
        if let roomsWithSwitches = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: Vera.Device.Category.Switch, Vera.Device.Category.DimmableLight) {
            for room in roomsWithSwitches {
                if let roomDevices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room, showExcluded: false, categories: Vera.Device.Category.Switch, Vera.Device.Category.DimmableLight) {
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
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.devices != nil {
            return self.devices!.count
        }
        
        return 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("OnCellIdentifier", forIndexPath: indexPath) as OnDeviceCell
        
        if indexPath.row < self.devices?.count {
            let device = self.devices![indexPath.row]
            cell.device = device
            cell.setup()
        }
        
        return cell as UICollectionViewCell
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row < self.devices?.count {
            let device = self.devices![indexPath.row]
            
            AppDelegate.appDelegate().veraAPI.setDeviceStatusWithNotification(device, newDeviceStatus: 0, newDeviceLevel: nil, completionHandler: { (error: NSError?) -> Void in
                
            })
        }
    }
}
