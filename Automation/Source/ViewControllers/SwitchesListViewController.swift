//
//  SwitchesListViewController.swift
//  Automation
//
//  Created by Scott Gruby on 10/4/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

class SwitchesListViewController: UITableViewController {

    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.current.userInterfaceIdiom == .pad {
            clearsSelectionOnViewWillAppear = true
            preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }

        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension

        NotificationCenter.default.addObserver(self, selector: #selector(SwitchesListViewController.unitInfoUpdated(_:)), name: NSNotification.Name(rawValue: VeraUnitInfoUpdated), object: nil)
        loadRooms(true)
    }

    func unitInfoUpdated(_ notification: Notification) {
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

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            // swiftlint:disable force_cast
            let controller = (segue.destination as! UINavigationController).topViewController as! SwitchesViewController
            // swiftlint:enable force_cast
            if let indexPath = tableView.indexPathForSelectedRow {
                if let roomsWithSwitches = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: VeraDevice.Category.switch, VeraDevice.Category.dimmableLight) {
                    let room = roomsWithSwitches[indexPath.row]
                    controller.room = room
                }

                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let roomsWithSwitches = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: VeraDevice.Category.switch, VeraDevice.Category.dimmableLight) {
                return roomsWithSwitches.count
            }

        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        if let roomsWithSwitches = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: VeraDevice.Category.switch, VeraDevice.Category.dimmableLight) {
            let room = roomsWithSwitches[indexPath.row]
            cell.textLabel!.text = room.name
        }

        cell.accessoryType = .disclosureIndicator

        return cell
    }
}
