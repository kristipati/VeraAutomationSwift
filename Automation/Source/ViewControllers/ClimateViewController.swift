//
//  ClimateViewController.swift
//  Automation
//
//  Created by Scott Gruby on 10/22/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera

protocol ThermostatProtocol {
    func changeHVAC(device: Device, fanMode: Device.FanMode?, hvacMode: Device.HVACMode?, coolTemp: Int?, heatTemp: Int?)
}

class ClimateViewController: UICollectionViewController, ThermostatProtocol {
    var devices: [Device]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "unitInfoUpdated:", name: Vera.VeraUnitInfoUpdated, object: nil)
        
        self.loadThermostats()
    }
    
    func unitInfoUpdated(notification: NSNotification) {
        self.loadThermostats()
    }
    
    func loadThermostats () {
        var devices = [Device]()
        if let roomsWithThermostats = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: Vera.Device.Category.Thermostat) {
            for room in roomsWithThermostats {
                if let roomDevices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room, showExcluded: false, categories: Vera.Device.Category.Thermostat) {
                    for device in roomDevices {
                            devices.append(device)
                    }
                }
            }
        }
        
        self.devices = devices
        
        self.collectionView.reloadData()
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.devices != nil {
            return self.devices!.count
        }
        
        return 0
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ClimateCell", forIndexPath: indexPath) as ThermostatCell
        
        if indexPath.row < self.devices?.count {
            let device = self.devices![indexPath.row]
            cell.device = device
            cell.delegate = self
            cell.setup()
        }
        
        return cell as UICollectionViewCell
    }
    
    func changeHVAC(device: Device, fanMode: Device.FanMode?, hvacMode: Device.HVACMode?, coolTemp: Int?, heatTemp: Int?) {
        AppDelegate.appDelegate().veraAPI.changeHVACWithNotification(device, fanMode: fanMode, hvacMode: hvacMode, coolTemp: coolTemp, heatTemp: heatTemp, completionHandler: { (error: NSError?) -> Void in
            
        })
        
    }

}
