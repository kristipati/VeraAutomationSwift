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

protocol AudioProtocol: class {
    func setDevicePower(_ device: VeraDevice, turnOn: Bool)
    func changeDeviceVolume(_ device: VeraDevice, increase: Bool)
    func setDeviceServer(_ device: VeraDevice, server: Int)
}

protocol SwitchProtocol: class {
    func changeDeviceLevel(_ device: VeraDevice, level: Int)
}

class DevicesViewController: UIViewController, SwitchProtocol, UICollectionViewDelegate, UICollectionViewDataSource, AudioProtocol {
    var room: VeraRoom?
    var items: DeviceItems?
    var roomType: RoomType = .switches

    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(UINib(nibName: DeviceCell.className(), bundle: nil), forCellWithReuseIdentifier: DeviceCell.className())
        collectionView.register(UINib(nibName: SceneCell.className(), bundle: nil), forCellWithReuseIdentifier: SceneCell.className())
        collectionView.register(UINib(nibName: AudioCell.className(), bundle: nil), forCellWithReuseIdentifier: AudioCell.className())

        if let cellLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            if roomType == .audio {
                cellLayout.itemSize = CGSize(width: 310, height: 200)
            } else {
                cellLayout.itemSize = CGSize(width: 150, height: 150)
            }
            cellLayout.minimumLineSpacing = 10
            cellLayout.minimumInteritemSpacing = 10
            cellLayout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
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
                    
                case .scenes:
                        if let scenes = AppDelegate.appDelegate().veraAPI.scenesForRoom(room: room) {
                            items = DeviceItems.scenes(devices: scenes)
                    }
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(DevicesViewController.unitInfoUpdated(_:)), name: NSNotification.Name(rawValue: VeraUnitInfoUpdated), object: nil)
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
        switch roomType {
            case .switches:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DeviceCell.className(), for: indexPath) as? DeviceCell {
                    if let items = items {
                        switch items {
                            case let .devices(devices):
                                if indexPath.row < devices.count {
                                    let device = devices[indexPath.row]
                                    cell.device = device
                                    cell.delegate = self
                                    cell.setup()
                            }

                            default:
                                break
                        }
                    }
                    return cell
                }

            case .scenes:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SceneCell.className(), for: indexPath) as? SceneCell {
                    if let items = items {
                        switch items {
                            case let .scenes(scenes):
                                if indexPath.row < scenes.count {
                                    let scene = scenes[indexPath.row]
                                    cell.scene = scene
                                    cell.setup()
                                }
                            default:
                                break
                        }
                    }
                    return cell
            }
            
            case .audio:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AudioCell.className(), for: indexPath) as? AudioCell {
                    if let items = items {
                        switch items {
                        case let .devices(devices):
                            if indexPath.row < devices.count {
                                let device = devices[indexPath.row]
                                cell.device = device
                                cell.delegate = self
                                cell.setup()
                            }
                            
                        default:
                            break
                        }
                    }
                    return cell
            }
        }

        return UICollectionViewCell(frame: .zero)
    }

    // MARK: UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch roomType {
            case .switches:
                if let items = items {
                    switch items {
                    case let .devices(devices):
                        if indexPath.row < devices.count {
                            let device = devices[indexPath.row]
                            var newStatus = 0
                            if let status = device.status {
                                if status == 0 {
                                    newStatus = 1
                                }
                            }

                            AppDelegate.appDelegate().veraAPI.setDeviceStatusWithNotification(device, newDeviceStatus: newStatus, newDeviceLevel: nil)
                        }
                        
                    default:
                        break
                    }
                }

            case .scenes:
                if let items = items {
                    switch items {
                        case let .scenes(scenes):
                            if indexPath.row < scenes.count {
                                let scene = scenes[indexPath.row]
                                AppDelegate.appDelegate().veraAPI.runSceneWithNotification(scene)
                            }
                        default:
                            break
                        }
                    
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
}
