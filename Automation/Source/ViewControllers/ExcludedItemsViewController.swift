//
//  ExcludedItemsViewController.swift
//  Automation
//
//  Created by Scott Gruby on 10/24/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

class ExcludedItemsViewController: UITableViewController {
    var showScenes = false
    var roomList = [VeraRoom]()
    var idsToExclude = [Int]()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: SettingsTableViewCell.className(), bundle: nil), forCellReuseIdentifier: SettingsTableViewCell.className())
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        tableView.tableFooterView = UIView(frame: .zero)

        navigationController?.navigationBar.isTranslucent = false

        if showScenes == true {
            if let scenes = AppDelegate.appDelegate().veraAPI.excludedScenes {
                idsToExclude += scenes
            }
        } else {
            if let scenes = AppDelegate.appDelegate().veraAPI.excludedDevices {
                idsToExclude += scenes
            }
        }
        buildRoomList()

        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if showScenes == true {
            AppDelegate.appDelegate().setExcludedSceneArray(array: idsToExclude)
        } else {
            AppDelegate.appDelegate().setExcludedDeviceArray(array: idsToExclude)
        }
    }

    func buildRoomList() {
        if let rooms = AppDelegate.appDelegate().veraAPI.getVeraUnit()?.rooms {
            for room in rooms {
                if showScenes == true {
                    if let scenes = AppDelegate.appDelegate().veraAPI.scenesForRoom(room: room, showExcluded: true) {
                        if scenes.isEmpty == false {
                            roomList.append(room)
                        }
                    }
                } else {
                    if let devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room: room, showExcluded: true, categories: .switch, .dimmableLight) {
                        if devices.isEmpty == false {
                            roomList.append(room)
                        }
                    }
                }

            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return roomList.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let room = roomList[section] as VeraRoom
        return room.name
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let room = roomList[section] as VeraRoom

        if showScenes == true {
            return AppDelegate.appDelegate().veraAPI.scenesForRoom(room: room, showExcluded: true)?.count ?? 0
        } else {
            return AppDelegate.appDelegate().veraAPI.devicesForRoom(room: room, showExcluded: true, categories: .switch, .dimmableLight)?.count ?? 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.className(), for: indexPath)
        cell.accessoryType = .none

        let room = roomList[indexPath.section] as VeraRoom

        if showScenes == true {
            if let scenes = AppDelegate.appDelegate().veraAPI.scenesForRoom(room: room, showExcluded: true) {
                let scene = scenes[indexPath.row]
                cell.textLabel!.text = scene.name
                if let id = scene.id {
                    if idsToExclude.contains(id) == true {
                        cell.accessoryType = .checkmark
                    }
                }
            }
        } else {
            if let devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room: room, showExcluded: true, categories: .switch, .dimmableLight) {
                let device = devices[indexPath.row]
                cell.textLabel!.text = device.name
                if let id = device.id {
                    if idsToExclude.contains(id) == true {
                        cell.accessoryType = .checkmark
                    }
                }
            }
        }

        cell.selectionStyle = .none

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let room = roomList[indexPath.section] as VeraRoom

        if showScenes == true {
            if let scenes = AppDelegate.appDelegate().veraAPI.scenesForRoom(room: room, showExcluded: true) {
                let scene = scenes[indexPath.row]
                if let id = scene.id {
                    if idsToExclude.contains(id) == true {
                        idsToExclude.removeObject(id)
                    } else {
                        idsToExclude.append(id)
                    }
                }
            }
        } else {
            if let devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room: room, showExcluded: true, categories: .switch, .dimmableLight) {
                let device = devices[indexPath.row]
                if let id = device.id {
                    if idsToExclude.contains(id) == true {
                        idsToExclude.removeObject(id)
                    } else {
                        idsToExclude.append(id)
                    }
                }
            }
        }

        tableView.reloadRows(at: [indexPath], with: .none)
    }
}
