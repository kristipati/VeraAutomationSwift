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

        tableView.register(UINib(nibName: SettingsTableViewCell.className(), bundle: nil), forCellReuseIdentifier: SettingsTableViewCell.className())
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        tableView.tableFooterView = UIView(frame: .zero)

        edgesForExtendedLayout = []
        extendedLayoutIncludesOpaqueBars = false
        tabBarController?.tabBar.isTranslucent = false
        navigationController?.navigationBar.isTranslucent = false
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        if section == 0 {
            return 3
        } else if section == 1 {
            return 1
        }
        return 0
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of rows in the section.
        return 2
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let vc = ExcludedItemsViewController()
                vc.title = NSLocalizedString("EXCLUDED_DEVICES_TITLE", comment: "")
                vc.showScenes = false
                navigationController?.pushViewController(vc, animated: true)
            } else if indexPath.row == 1 {
                let vc = ExcludedItemsViewController()
                vc.title = NSLocalizedString("EXCLUDED_SCENES_TITLE", comment: "")
                vc.showScenes = true
                navigationController?.pushViewController(vc, animated: true)
            }
        } else if indexPath.section == 1 {
            AppDelegate.appDelegate().logout()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.className(), for: indexPath)
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
                switch indexPath.row {
                    case 0:
                        cell.textLabel!.text = NSLocalizedString("EXCLUDED_DEVICES_TITLE", comment: "")
                        cell.accessoryView = nil

                    case 1:
                        cell.textLabel!.text = NSLocalizedString("EXCLUDED_SCENES_TITLE", comment: "")
                        cell.accessoryView = nil

                    case 2:
                        cell.accessoryType = .none
                        cell.accessoryView = audioSwitch
                        audioSwitch.isOn = UserDefaults.standard.bool(forKey: kShowAudioTabDefault)
                        audioSwitch.addTarget(self, action: #selector(SettingsViewController.audioTabChanged), for: .valueChanged)
                        cell.textLabel!.text = NSLocalizedString("SHOW_AUDIO_TAB", comment: "")
                        cell.selectionStyle = .none
                        return cell

                    default:
                        return UITableViewCell()
                }

                return cell

        case 1:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.className(), for: indexPath)
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

    @objc func audioTabChanged() {
        UserDefaults.standard.set(audioSwitch.isOn, forKey: kShowAudioTabDefault)
        UserDefaults.standard.synchronize()
        AppDelegate.appDelegate().showHideAudioTab()
    }
}
