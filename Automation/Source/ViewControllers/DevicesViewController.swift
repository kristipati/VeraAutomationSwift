//
//  SwitchesViewController.swift
//  Automation
//
//  Created by Scott Gruby on 11/2/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

enum DeviceItems {
    case devices(devices: [VeraDevice])
    case scenes(devices: [VeraScene])
}

protocol DeviceCellProtocol: class {
    func setDevicePower(_ device: VeraDevice, turnOn: Bool)
    func changeDeviceVolume(_ device: VeraDevice, increase: Bool)
    func setDeviceServer(_ device: VeraDevice, server: Int)
    func changeDeviceLevel(_ device: VeraDevice, level: Int)
    func setDeviceLocked(_ device: VeraDevice, locked: Bool)
    func changeHVAC(_ device: VeraDevice, fanMode: VeraDevice.FanMode?, hvacMode: VeraDevice.HVACMode?, coolTemp: Int?, heatTemp: Int?)
}

class DevicesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, DeviceCellProtocol {
    var room: VeraRoom?
    var items: DeviceItems?
    var roomType: RoomType = .switches

    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(UINib(nibName: DeviceCell.className(), bundle: nil), forCellWithReuseIdentifier: DeviceCell.className())
        collectionView.register(UINib(nibName: SceneCell.className(), bundle: nil), forCellWithReuseIdentifier: SceneCell.className())
        collectionView.register(UINib(nibName: AudioCell.className(), bundle: nil), forCellWithReuseIdentifier: AudioCell.className())
        collectionView.register(UINib(nibName: LockCell.className(), bundle: nil), forCellWithReuseIdentifier: LockCell.className())
        collectionView.register(UINib(nibName: ThermostatCell.className(), bundle: nil), forCellWithReuseIdentifier: ThermostatCell.className())
        collectionView.register(UINib(nibName: OnDeviceCell.className(), bundle: nil), forCellWithReuseIdentifier: OnDeviceCell.className())

        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true

        if let cellLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            switch roomType {
                case .audio:
                    cellLayout.itemSize = CGSize(width: 310, height: 200)
                case .climate:
                    cellLayout.itemSize = CGSize(width: 300, height: 250)
                case .locks, .scenes, .switches, .on:
                    cellLayout.itemSize = CGSize(width: 150, height: 150)
            }
            cellLayout.minimumLineSpacing = 10
            cellLayout.minimumInteritemSpacing = 10
            cellLayout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        }

        switch roomType {
            case .locks:
                loadLocks()
            case .climate:
                loadThermostats()
            case .on:
                loadOnDevices()
            default:
                break
        }

        if let room = room {
            title = room.name
            switch roomType {
                case .switches:
                    if let devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room: room, categories: .switch, .dimmableLight) {
                        items = DeviceItems.devices(devices: devices)
                    }

                case .audio:
                    if let devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room: room, categories: .audio) {
                        items = DeviceItems.devices(devices: devices)
                    }

                case .locks, .climate, .on:
                    break

                case .scenes:
                        if let scenes = AppDelegate.appDelegate().veraAPI.scenesForRoom(room: room) {
                            items = DeviceItems.scenes(devices: scenes)
                    }
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(DevicesViewController.unitInfoUpdated(_:)), name: NSNotification.Name(rawValue: VeraUnitInfoUpdated), object: nil)
    }

    func loadLocks() {
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

        items = DeviceItems.devices(devices: newDevices)
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

        items = DeviceItems.devices(devices: thermoDevices)
    }

    func loadOnDevices () {
        var newDevices = [VeraDevice]()
        if let roomsWithSwitches = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: VeraDevice.Category.switch, VeraDevice.Category.dimmableLight) {
            for room in roomsWithSwitches {
                if let roomDevices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room: room, showExcluded: false, categories: VeraDevice.Category.switch, VeraDevice.Category.dimmableLight) {
                    for device in roomDevices {
                        if let status = device.status {
                            if status == 1 {
                                newDevices.append(device)
                            }
                        }
                    }
                }
            }
        }
        items = DeviceItems.devices(devices: newDevices)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }

    @objc func unitInfoUpdated(_ notification: Notification) {
        var fullload = false
        if let info = (notification as NSNotification).userInfo as? [String: AnyObject] {
            if let tempFullLoad = info[VeraUnitInfoFullLoad] as? Bool {
                fullload = tempFullLoad
            }
        }

        if fullload == true {
            room = nil
            items = nil
            title = nil
            navigationItem.leftBarButtonItem = nil
        }

        switch roomType {
            case .locks:
                loadLocks()
            case .climate:
                loadThermostats()
            case .on:
                loadOnDevices()
            default:
                break
        }

        collectionView!.reloadData()
    }

    // MARK: UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let items = items {
            switch items {
                case let .devices(devices):
                    return devices.count
                case let .scenes(scenes):
                    return scenes.count
            }
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cellReuseIdentifier = ""

        switch roomType {
            case .switches:
                cellReuseIdentifier = DeviceCell.className()
            case .on:
                cellReuseIdentifier = OnDeviceCell.className()
            case .locks:
                cellReuseIdentifier = LockCell.className()
            case .climate:
                cellReuseIdentifier = ThermostatCell.className()
            case .audio:
                cellReuseIdentifier = AudioCell.className()
            case .scenes:
                cellReuseIdentifier = SceneCell.className()
        }

        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as? BaseCell {
            cell.delegate = self

            if let items = items {
                switch items {
                    case let .devices(devices):
                        if indexPath.row < devices.count {
                            let device = devices[indexPath.row]
                            cell.device = device
                        }
                    case let .scenes(scenes):
                        if indexPath.row < scenes.count {
                            let scene = scenes[indexPath.row]
                            cell.scene = scene
                        }
                }
            }
            cell.setup()
            return cell
        }

        return UICollectionViewCell(frame: .zero)
    }

    // MARK: UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch roomType {
            case .switches, .on:
                if let items = items, case .devices(let devices) = items, indexPath.row < devices.count {
                    let device = devices[indexPath.row]
                    var newStatus = 0
                    if let status = device.status {
                        if status == 0 {
                            newStatus = 1
                        }
                    }

                    if roomType == .on {
                        newStatus = 0
                    }

                    AppDelegate.appDelegate().veraAPI.setDeviceStatusWithNotification(device, newDeviceStatus: newStatus, newDeviceLevel: nil)
            }

            case .scenes:
                if let items = items, case .scenes(let scenes) = items, indexPath.row < scenes.count {
                    let scene = scenes[indexPath.row]
                    AppDelegate.appDelegate().veraAPI.runSceneWithNotification(scene)
                }

            default:
                break
        }
    }

    func changeDeviceLevel(_ device: VeraDevice, level: Int) {
        AppDelegate.appDelegate().veraAPI.setDeviceStatusWithNotification(device, newDeviceStatus: nil, newDeviceLevel: level)
    }

    func setDevicePower(_ device: VeraDevice, turnOn: Bool) {
        AppDelegate.appDelegate().veraAPI.setAudioPowerWithNotification(device, on:turnOn)
    }

    func changeDeviceVolume(_ device: VeraDevice, increase: Bool) {
        AppDelegate.appDelegate().veraAPI.changeAudioVolumeWithNotification(device, increase:increase)
    }

    func setDeviceServer(_ device: VeraDevice, server: Int) {
        AppDelegate.appDelegate().veraAPI.setAudioInputWithNotification(device, input:server)
    }

    func setDeviceLocked(_ device: VeraDevice, locked: Bool) {
        AppDelegate.appDelegate().veraAPI.setLockStateWithNotification(device, locked:locked)
    }

    func changeHVAC(_ device: VeraDevice, fanMode: VeraDevice.FanMode?, hvacMode: VeraDevice.HVACMode?, coolTemp: Int?, heatTemp: Int?) {
        AppDelegate.appDelegate().veraAPI.changeHVACWithNotification(device, fanMode: fanMode, hvacMode: hvacMode, coolTemp: coolTemp, heatTemp: heatTemp)
    }
}
