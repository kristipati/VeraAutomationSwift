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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        if (section == 0) {
            return 3;
        } else if (section == 1) {
            return 1;
        }
        return 0
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of rows in the section.
        return 2
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if (indexPath as NSIndexPath).section == 1 {
            AppDelegate.appDelegate().logout()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath as NSIndexPath).section {
            case 0:
                switch (indexPath as NSIndexPath).row {
                case 0:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ExcludedDevicesCellIdentifier", for: indexPath) 
                    cell.textLabel!.text = NSLocalizedString("EXCLUDED_DEVICES_TITLE", comment: "")
                    cell.accessoryView = nil
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                    return cell
                    
                case 1:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ExcludedScenesCellIdentifier", for: indexPath) 
                    cell.textLabel!.text = NSLocalizedString("EXCLUDED_SCENES_TITLE", comment: "")
                    cell.accessoryView = nil
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                    return cell
                    
                case 2:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleCellIdentifier", for: indexPath) 
                    cell.accessoryType = .none
                    cell.accessoryView = self.audioSwitch
                    self.audioSwitch.isOn = UserDefaults.standard.bool(forKey: kShowAudioTabDefault)
                    self.audioSwitch.addTarget(self, action: #selector(SettingsViewController.audioTabChanged), for: .valueChanged)
                    cell.textLabel!.text = NSLocalizedString("SHOW_AUDIO_TAB", comment: "")
                    cell.selectionStyle = .none
                    return cell
                    
                default:
                    return UITableViewCell()
            }
            
        case 1:
            switch ((indexPath as NSIndexPath).row) {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "LogoutCellIdentifier", for: indexPath) 
                cell.textLabel!.text = NSLocalizedString("LOGOUT_LABEL", comment: "")
                cell.accessoryView = nil
                cell.accessoryType = .none
                cell.selectionStyle = .none
                return cell
                
            default:
                return UITableViewCell()

            }
        default:
            return UITableViewCell()
        }
    }
    
    func audioTabChanged() {
        UserDefaults.standard.set(self.audioSwitch.isOn, forKey: kShowAudioTabDefault)
        UserDefaults.standard.synchronize()
        AppDelegate.appDelegate().showHideAudioTab()
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if let destVC = segue.destination as? ExcludedItemsViewController {
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
