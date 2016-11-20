//
//  ScenesViewController.swift
//  Automation
//
//  Created by Scott Gruby on 11/2/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

class ScenesViewController: UICollectionViewController {
    var room: VeraRoom?
    var scenes: [VeraScene]?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let room = room {
            scenes = AppDelegate.appDelegate().veraAPI.scenesForRoom(room: room)
            title = room.name
        }

        NotificationCenter.default.addObserver(self, selector: #selector(ScenesViewController.unitInfoUpdated(_:)), name: NSNotification.Name(rawValue: VeraUnitInfoUpdated), object: nil)
    }

    func unitInfoUpdated(_ notification: Notification) {
        var fullload = false
        if let info = (notification as NSNotification).userInfo as? Dictionary<String, AnyObject> {
            if let tempFullLoad = info[VeraUnitInfoFullLoad] as? Bool {
                fullload = tempFullLoad
            }
        }

        if fullload == true {
            room = nil
            scenes = nil
            title = nil
            navigationItem.leftBarButtonItem = nil
        }
        collectionView!.reloadData()
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return scenes?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SceneCell", for: indexPath) as! SceneCell
    
        if let scenes = scenes, indexPath.row < scenes.count {
            let scene = scenes[indexPath.row]
            cell.scene = scene
            cell.setup()
        }
        
        return cell as UICollectionViewCell
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let scenes = scenes, indexPath.row < scenes.count {
            let scene = scenes[indexPath.row]
            
            AppDelegate.appDelegate().veraAPI.runSceneWithNotification(scene)
        }
    }
}
