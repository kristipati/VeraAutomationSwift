//
//  SwitchesListViewController.swift
//  Automation
//
//  Created by Scott Gruby on 10/4/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera

class SwitchesListViewController: UITableViewController {

    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.clearsSelectionOnViewWillAppear = true
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
        
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableViewAutomaticDimension;

        NotificationCenter.default.addObserver(self, selector: #selector(SwitchesListViewController.unitInfoUpdated(_:)), name: NSNotification.Name(rawValue: Vera.VeraUnitInfoUpdated), object: nil)
        self.loadRooms(true)
    }
    
    func unitInfoUpdated(_ notification: Notification) {
        var fullload = false
        if let info = (notification as NSNotification).userInfo as? Dictionary<String, AnyObject> {
            if let tempFullLoad = info[VeraUnitInfoFullLoad] as? Bool {
                fullload = tempFullLoad
            }
        }
        self.loadRooms(fullload)
    }

    func loadRooms(_ fullload: Bool) {
        if fullload == true {
            self.navigationController?.popToRootViewController(animated: false)
            if let indexPath = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRow(at: indexPath, animated: false)
            }
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            let controller = (segue.destination as! UINavigationController).topViewController as! SwitchesViewController
            if let indexPath = self.tableView.indexPathForSelectedRow {
                if let roomsWithSwitches = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: Vera.Device.Category.switch, Vera.Device.Category.dimmableLight) {
                    let room = roomsWithSwitches[(indexPath as NSIndexPath).row]
                    controller.room = room
                }

                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let roomsWithSwitches = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: Vera.Device.Category.switch, Vera.Device.Category.dimmableLight) {
                return roomsWithSwitches.count
            }
        
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        if let roomsWithSwitches = AppDelegate.appDelegate().veraAPI.roomsWithDevices(categories: Vera.Device.Category.switch, Vera.Device.Category.dimmableLight) {
            let room = roomsWithSwitches[(indexPath as NSIndexPath).row]
            cell.textLabel!.text = room.name
        }
        
        cell.accessoryType = .disclosureIndicator

        return cell
    }
}

