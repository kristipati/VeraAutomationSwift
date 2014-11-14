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
        self.tableView.rowHeight = UITableViewAutomaticDimension;

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

        self.tableView.tableFooterView = UIView(frame: CGRectMake(0, 0, 0, 0))
    }
    
    override func viewWillDisappear(animated: Bool) {
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
                    if let devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room, showExcluded: true, categories: .Switch, .DimmableLight) {
                        if devices.isEmpty == false {
                            roomList.append(room)
                        }
                    }
                }

            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.roomList.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let room = roomList[section] as Room
        return room.name
    }


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let room = roomList[section] as Room

        if self.showScenes == true {
            if let scenes = AppDelegate.appDelegate().veraAPI.scenesForRoom(room, showExcluded: true) {
                return scenes.count
            }
        } else {
            if let devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room, showExcluded: true, categories: .Switch, .DimmableLight) {
                return devices.count
            }
        }

        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DeviceCellIdentifier", forIndexPath: indexPath) as UITableViewCell

        cell.accessoryType = .None
        
        let room = roomList[indexPath.section] as Room

        if self.showScenes == true {
            if let scenes = AppDelegate.appDelegate().veraAPI.scenesForRoom(room, showExcluded: true) {
                let scene = scenes[indexPath.row]
                cell.textLabel.text = scene.name
                if let id = scene.id {
                    if contains(idsToExclude, id) == true {
                        cell.accessoryType = .Checkmark
                    }
                }
            }
        } else {
            if let devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room, showExcluded: true, categories: .Switch, .DimmableLight) {
                let device = devices[indexPath.row]
                cell.textLabel.text = device.name
                if let id = device.id {
                    if contains(idsToExclude, id) == true {
                        cell.accessoryType = .Checkmark
                    }
                }
            }
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let room = roomList[indexPath.section] as Room

        if self.showScenes == true {
            if let scenes = AppDelegate.appDelegate().veraAPI.scenesForRoom(room, showExcluded: true) {
                let scene = scenes[indexPath.row]
                if let id = scene.id {
                    if contains(self.idsToExclude, id) == true {
                        idsToExclude.removeObject(id)
                    } else {
                        idsToExclude.append(id)
                    }
                }
            }
        } else {
            if let devices = AppDelegate.appDelegate().veraAPI.devicesForRoom(room, showExcluded: true, categories: .Switch, .DimmableLight) {
                let device = devices[indexPath.row]
                if let id = device.id {
                    if contains(self.idsToExclude, id) == true {
                        idsToExclude.removeObject(id)
                    } else {
                        idsToExclude.append(id)
                    }
                }
            }
        }

        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
}

