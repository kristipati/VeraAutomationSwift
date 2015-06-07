//
//  SwitchesViewController.swift
//  Automation
//
//  Created by Scott Gruby on 11/2/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera

protocol SwitchProtocol {
    func changeDeviceLevel(device: Device, level: Int)
}

class SwitchesViewController: UICollectionViewController, SwitchProtocol {
    var room: Room?
    var devices: [Device]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if self.room != nil {
            self.devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(self.room!, categories: .Switch, .DimmableLight)
            self.title = self.room?.name
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "unitInfoUpdated:", name: Vera.VeraUnitInfoUpdated, object: nil)
    }


    func unitInfoUpdated(notification: NSNotification) {
        var fullload = false
        if let info = notification.userInfo as? Dictionary<String, AnyObject> {
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

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.devices != nil {
            return self.devices!.count
        }

        return 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("DeviceCell", forIndexPath: indexPath) as! DeviceCell
    
        if indexPath.row < self.devices?.count {
            let device = self.devices![indexPath.row]
            cell.device = device
            cell.delegate = self
            cell.setup()
        }
    
        return cell as UICollectionViewCell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row < self.devices?.count {
            let device = self.devices![indexPath.row]
            var newStatus = 0
            if let status = device.status {
                if status == 0 {
                    newStatus = 1
                }
            }
            
            AppDelegate.appDelegate().veraAPI.setDeviceStatusWithNotification(device, newDeviceStatus: newStatus, newDeviceLevel: nil, completionHandler: { (error: NSError?) -> Void in
                
            })
        }
    }
    
    func changeDeviceLevel(device: Device, level: Int) {
        AppDelegate.appDelegate().veraAPI.setDeviceStatusWithNotification(device, newDeviceStatus: nil, newDeviceLevel: level, completionHandler: { (error: NSError?) -> Void in
            
        })
    }
}
