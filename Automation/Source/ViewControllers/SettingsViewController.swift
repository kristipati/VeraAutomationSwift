//
//  SettingsViewController.swift
//  Automation
//
//  Created by Scott Gruby on 10/22/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    var audioSwitch = UISwitch()
    var ui5Switch = UISwitch()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.tableFooterView = UIView(frame: CGRectMake(0, 0, 0, 0))
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        if (section == 0) {
            return 3;
        } else if (section == 1) {
            return 2;
        }
        return 0
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of rows in the section.
        return 2
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 1 {
            AppDelegate.appDelegate().logout()
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
            case 0:
                switch indexPath.row {
                case 0:
                    let cell = tableView.dequeueReusableCellWithIdentifier("ExcludedDevicesCellIdentifier", forIndexPath: indexPath) 
                    cell.textLabel!.text = NSLocalizedString("EXCLUDED_DEVICES_TITLE", comment: "")
                    cell.accessoryView = nil
                    cell.accessoryType = .DisclosureIndicator
                    cell.selectionStyle = .Default
                    return cell
                    
                case 1:
                    let cell = tableView.dequeueReusableCellWithIdentifier("ExcludedScenesCellIdentifier", forIndexPath: indexPath) 
                    cell.textLabel!.text = NSLocalizedString("EXCLUDED_SCENES_TITLE", comment: "")
                    cell.accessoryView = nil
                    cell.accessoryType = .DisclosureIndicator
                    cell.selectionStyle = .Default
                    return cell
                    
                case 2:
                    let cell = tableView.dequeueReusableCellWithIdentifier("ToggleCellIdentifier", forIndexPath: indexPath) 
                    cell.accessoryType = .None
                    cell.accessoryView = self.audioSwitch
                    self.audioSwitch.on = NSUserDefaults.standardUserDefaults().boolForKey(kShowAudioTabDefault)
                    self.audioSwitch.addTarget(self, action: "audioTabChanged", forControlEvents: .ValueChanged)
                    cell.textLabel!.text = NSLocalizedString("SHOW_AUDIO_TAB", comment: "")
                    cell.selectionStyle = .None
                    return cell
                    
                default:
                    return UITableViewCell()
            }
            
        case 1:
            switch (indexPath.row) {
            case 0:
                let cell = tableView.dequeueReusableCellWithIdentifier("LogoutCellIdentifier", forIndexPath: indexPath) 
                cell.textLabel!.text = NSLocalizedString("LOGOUT_LABEL", comment: "")
                cell.accessoryView = nil
                cell.accessoryType = .None
                cell.selectionStyle = .None
                return cell
                
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier("ToggleCellIdentifier", forIndexPath: indexPath) 
                cell.accessoryType = .None
                cell.accessoryView = self.ui5Switch
                self.ui5Switch.on = NSUserDefaults.standardUserDefaults().boolForKey(kUseUI5Default)
                self.ui5Switch.addTarget(self, action: "ui5Changed", forControlEvents: .ValueChanged)
                cell.textLabel!.text = NSLocalizedString("USE_UI_5_LABEL", comment: "")
                cell.selectionStyle = .None
                return cell
            default:
                return UITableViewCell()

            }
        default:
            return UITableViewCell()
        }
    }
    
    func audioTabChanged() {
        NSUserDefaults.standardUserDefaults().setBool(self.audioSwitch.on, forKey: kShowAudioTabDefault)
        NSUserDefaults.standardUserDefaults().synchronize()
        AppDelegate.appDelegate().showHideAudioTab()
    }

    func ui5Changed() {
        NSUserDefaults.standardUserDefaults().setBool(self.ui5Switch.on, forKey: kUseUI5Default)
        NSUserDefaults.standardUserDefaults().synchronize()
        AppDelegate.appDelegate().logout()
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if let destVC = segue.destinationViewController as? ExcludedItemsViewController {
            if let identifier = segue.identifier {
                switch identifier {
                    case "ExcludedScenesSegue":
                        destVC.title = NSLocalizedString("EXCLUDED_SCENES_TITLE", comment: "")
                        destVC.showScenes = true
                    case "ExcludedDevicesSegue":
                        destVC.title = NSLocalizedString("EXCLUDED_DEVICES_TITLE", comment: "")
                        destVC.showScenes = false
                    default:
                        destVC.title = ""
                }
            }
            
        }
    }

}
