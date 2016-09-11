//
//  ClimateViewController.swift
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


protocol ThermostatProtocol {
    func changeHVAC(_ device: Device, fanMode: Device.FanMode?, hvacMode: Device.HVACMode?, coolTemp: Int?, heatTemp: Int?)
}

class ClimateViewController: UICollectionViewController, ThermostatProtocol {
    var devices: [Device]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ClimateViewController.unitInfoUpdated(_:)), name: NSNotification.Name(rawValue: Vera.VeraUnitInfoUpdated), object: nil)
        
        self.loadThermostats()
    }
    
    func unitInfoUpdated(_ notification: Notification) {
        self.loadThermostats()
    }
    
    func loadThermostats () {
        var devices = [Device]()
        if let roomsWithThermostats = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: Vera.Device.Category.thermostat) {
            for room in roomsWithThermostats {
                if let roomDevices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room, showExcluded: false, categories: Vera.Device.Category.thermostat) {
                    for device in roomDevices {
                            devices.append(device)
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ClimateCell", for: indexPath) as! ThermostatCell
        
        if (indexPath as NSIndexPath).row < self.devices?.count {
            let device = self.devices![(indexPath as NSIndexPath).row]
            cell.device = device
            cell.delegate = self
            cell.setup()
        }
        
        return cell as UICollectionViewCell
    }
    
    func changeHVAC(_ device: Device, fanMode: Device.FanMode?, hvacMode: Device.HVACMode?, coolTemp: Int?, heatTemp: Int?) {
        AppDelegate.appDelegate().veraAPI.changeHVACWithNotification(device, fanMode: fanMode, hvacMode: hvacMode, coolTemp: coolTemp, heatTemp: heatTemp)
        
    }

}
