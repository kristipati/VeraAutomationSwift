//
//  ClimateViewController.swift
//  Automation
//
//  Created by Scott Gruby on 10/22/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

protocol ThermostatProtocol: class {
    func changeHVAC(_ device: VeraDevice, fanMode: VeraDevice.FanMode?, hvacMode: VeraDevice.HVACMode?, coolTemp: Int?, heatTemp: Int?)
}

class ClimateViewController: UICollectionViewController, ThermostatProtocol {
    var devices: [VeraDevice]?

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(ClimateViewController.unitInfoUpdated(_:)), name: NSNotification.Name(rawValue: VeraUnitInfoUpdated), object: nil)

        loadThermostats()
    }

    func unitInfoUpdated(_ notification: Notification) {
        loadThermostats()
    }

    func loadThermostats () {
        var thermoDevices = [VeraDevice]()
        if let roomsWithThermostats = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: VeraDevice.Category.thermostat) {
            for room in roomsWithThermostats {
                if let roomDevices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room: room, showExcluded: false, categories: VeraDevice.Category.thermostat) {
                    for device in roomDevices {
                            thermoDevices.append(device)
                    }
                }
            }
        }

        devices = thermoDevices

        collectionView!.reloadData()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return devices?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // swiftlint:disable force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ClimateCell", for: indexPath) as! ThermostatCell
        // swiftlint:enable force_cast

        if let devices = devices, indexPath.row < devices.count {
            let device = devices[indexPath.row]
            cell.device = device
            cell.delegate = self
            cell.setup()
        }

        return cell
    }

    func changeHVAC(_ device: VeraDevice, fanMode: VeraDevice.FanMode?, hvacMode: VeraDevice.HVACMode?, coolTemp: Int?, heatTemp: Int?) {
        AppDelegate.appDelegate().veraAPI.changeHVACWithNotification(device, fanMode: fanMode, hvacMode: hvacMode, coolTemp: coolTemp, heatTemp: heatTemp)

    }

}
