//
//  ScenesListViewController.swift
//  Automation
//
//  Created by Scott Gruby on 10/4/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera

class ScenesListViewController: UITableViewController {

    var objects = NSMutableArray()


    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }

        self.tableView.tableFooterView = UIView(frame: CGRectMake(0, 0, 0, 0))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.splitViewController?.tabBarItem.title
        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableViewAutomaticDimension;

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "unitInfoUpdated:", name: Vera.VeraUnitInfoUpdated, object: nil)
        self.loadRooms(true)
        self.tableView.reloadData()
    }

    func unitInfoUpdated(notification: NSNotification) {
        var fullload = false
        if let info = notification.userInfo as? Dictionary<String, AnyObject> {
            if let tempFullLoad = info[VeraUnitInfoFullLoad] as? Bool {
                fullload = tempFullLoad
            }
        }
        self.loadRooms(fullload)
    }
    
    func loadRooms(fullload: Bool) {
        if fullload == true {
            self.navigationController?.popToRootViewControllerAnimated(false)
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
            }
            self.tableView.reloadData()
        }
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let controller = (segue.destinationViewController as UINavigationController).topViewController as ScenesViewController
                if let roomsWithScenes = AppDelegate.appDelegate().veraAPI.roomsWithScenes() {
                    let room = roomsWithScenes[indexPath.row]
                    controller.room = room
                }

                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let roomsWithScenes = AppDelegate.appDelegate().veraAPI.roomsWithScenes() {
            return roomsWithScenes.count
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        
        if let roomsWithScenes = AppDelegate.appDelegate().veraAPI.roomsWithScenes() {
            let room = roomsWithScenes[indexPath.row]
            cell.textLabel.text = room.name
        }
        
        cell.accessoryType = .DisclosureIndicator
        
        return cell
    }

}

