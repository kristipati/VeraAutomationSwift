//
//  ExcludedItemsViewController.swift
//  Automation
//
//  Created by Scott Gruby on 10/24/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera

class ExcludedItemsViewController: UITableViewController {
    var showScenes = false
    var roomList = [Room]()
    var idsToExclude = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableViewAutomaticDimension

        if self.showScenes == true {
            if let scenes = AppDelegate.appDelegate().veraAPI.excludedScenes {
                idsToExclude += scenes
            }
        } else {
            if let scenes = AppDelegate.appDelegate().veraAPI.excludedDevices {
                idsToExclude += scenes
            }
        }
        self.buildRoomList()

        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.showScenes == true {
            AppDelegate.appDelegate().setExcludedSceneArray(idsToExclude)
        } else {
            AppDelegate.appDelegate().setExcludedDeviceArray(idsToExclude)
        }
    }
    
    func buildRoomList() {
        if let rooms = AppDelegate.appDelegate().veraAPI.getVeraUnit()?.rooms {
            for room in rooms {
                if self.showScenes {
                    if let scenes = AppDelegate.appDelegate().veraAPI.scenesForRoom(room, showExcluded: true) {
                        if scenes.isEmpty == false {
                            roomList.append(room)
                        }
                    }
                } else {
                    if let devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room, showExcluded: true, categories: .switch, .dimmableLight) {
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
        return self.roomList.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let room = roomList[section] as Room
        return room.name
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let room = roomList[section] as Room

        if self.showScenes == true {
            if let scenes = AppDelegate.appDelegate().veraAPI.scenesForRoom(room, showExcluded: true) {
                return scenes.count
            }
        } else {
            if let devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room, showExcluded: true, categories: .switch, .dimmableLight) {
                return devices.count
            }
        }

        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCellIdentifier", for: indexPath)
        cell.accessoryType = .none
        
        let room = roomList[(indexPath as NSIndexPath).section] as Room

        if self.showScenes == true {
            if let scenes = AppDelegate.appDelegate().veraAPI.scenesForRoom(room, showExcluded: true) {
                let scene = scenes[(indexPath as NSIndexPath).row]
                cell.textLabel!.text = scene.name
                if let id = scene.id {
                    if idsToExclude.contains(id) == true {
                        cell.accessoryType = .checkmark
                    }
                }
            }
        } else {
            if let devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room, showExcluded: true, categories: .switch, .dimmableLight) {
                let device = devices[(indexPath as NSIndexPath).row]
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
        
        let room = roomList[(indexPath as NSIndexPath).section] as Room

        if self.showScenes == true {
            if let scenes = AppDelegate.appDelegate().veraAPI.scenesForRoom(room, showExcluded: true) {
                let scene = scenes[(indexPath as NSIndexPath).row]
                if let id = scene.id {
                    if self.idsToExclude.contains(id) == true {
                        idsToExclude.removeObject(id)
                    } else {
                        idsToExclude.append(id)
                    }
                }
            }
        } else {
            if let devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room, showExcluded: true, categories: .switch, .dimmableLight) {
                let device = devices[(indexPath as NSIndexPath).row]
                if let id = device.id {
                    if self.idsToExclude.contains(id) == true {
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

