//
//  RoomsTableViewController.swift
//  Automation
//
//  Created by Scott Gruby on 9/15/17.
//  Copyright © 2017 Gruby Solutions. All rights reserved.
//

import UIKit

enum RoomType {
    case switches, audio, scenes, locks, climate, on
}

class RoomsTableViewController: UITableViewController {
    var roomType: RoomType = .switches

    override func viewDidLoad() {
        super.viewDidLoad()

        if UIDevice.current.userInterfaceIdiom == .pad {
            clearsSelectionOnViewWillAppear = true
            preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }

        tableView.register(UINib(nibName: RoomTableViewCell.className(), bundle: nil), forCellReuseIdentifier: RoomTableViewCell.className())
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        tableView.tableFooterView = UIView(frame: .zero)

        edgesForExtendedLayout = []
        extendedLayoutIncludesOpaqueBars = false
        tabBarController?.tabBar.isTranslucent = false
        navigationController?.navigationBar.isTranslucent = false

        tableView.reloadData()

        NotificationCenter.default.addObserver(self, selector: #selector(RoomsTableViewController.unitInfoUpdated(_:)), name: NSNotification.Name(rawValue: VeraUnitInfoUpdated), object: nil)
        loadRooms(true)
    }

    @objc func unitInfoUpdated(_ notification: Notification) {
        var fullload = false
        if let info = (notification as NSNotification).userInfo as? [String: AnyObject] {
            if let tempFullLoad = info[VeraUnitInfoFullLoad] as? Bool {
                fullload = tempFullLoad
            }
        }
        loadRooms(fullload)
    }

    func loadRooms(_ fullload: Bool) {
        if fullload == true {
            _ = navigationController?.popToRootViewController(animated: false)
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: indexPath, animated: false)
            }
            tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch roomType {
            case .switches:
                if let roomsWithSwitches = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: VeraDevice.Category.switch, VeraDevice.Category.dimmableLight) {
                    return roomsWithSwitches.count
                }

            case .audio:
                if let roomsWithAudio = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: VeraDevice.Category.audio) {
                    return roomsWithAudio.count
                }

            case .scenes:
                if let roomsWithScenes = AppDelegate.appDelegate().veraAPI.roomsWithScenes() {
                    return roomsWithScenes.count
                }
            
            default:
                break
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: RoomTableViewCell.className(), for: indexPath) as? RoomTableViewCell {
            cell.accessoryType = .disclosureIndicator

            switch roomType {
                case .switches:
                    if let roomsWithSwitches = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: VeraDevice.Category.switch, VeraDevice.Category.dimmableLight) {
                        let room = roomsWithSwitches[indexPath.row]
                        cell.room = room.name
                    }

                case .audio:
                    if let roomsWithAudio = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: VeraDevice.Category.audio) {
                        let room = roomsWithAudio[indexPath.row]
                        cell.room = room.name
                    }

                case .scenes:
                    if let roomsWithScenes = AppDelegate.appDelegate().veraAPI.roomsWithScenes() {
                        cell.room = roomsWithScenes[indexPath.row].name
                    }

                default:
                    break
            }
            return cell
        }

        return UITableViewCell(style: .default, reuseIdentifier: "")
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = DevicesViewController()
        vc.roomType = roomType

        switch roomType {
            case .switches:
                if let roomsWithSwitches = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: VeraDevice.Category.switch, VeraDevice.Category.dimmableLight) {
                    let room = roomsWithSwitches[indexPath.row]
                    vc.room = room
                }
            case .audio:
                if let roomsWithAudio = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: VeraDevice.Category.audio) {
                    let room = roomsWithAudio[indexPath.row]
                    vc.room = room
                }
            
            case .scenes:
                if let roomsWithScenes = AppDelegate.appDelegate().veraAPI.roomsWithScenes() {
                    let room = roomsWithScenes[indexPath.row]
                    vc.room = room
                }

            default:
                break
        }

        if splitViewController != nil {
            splitViewController?.showDetailViewController(vc, sender: self)
        } else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
