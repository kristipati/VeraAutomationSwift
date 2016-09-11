//
//  ScenesViewController.swift
//  Automation
//
//  Created by Scott Gruby on 11/2/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class ScenesViewController: UICollectionViewController {
    var room: Room?
    var scenes: [Scene]?

    override func viewDidLoad() {
        super.viewDidLoad()

        if self.room != nil {
            self.scenes = AppDelegate.appDelegate().veraAPI.scenesForRoom(self.room!)
            self.title = self.room?.name
        }

        NotificationCenter.default.addObserver(self, selector: #selector(ScenesViewController.unitInfoUpdated(_:)), name: NSNotification.Name(rawValue: Vera.VeraUnitInfoUpdated), object: nil)
    }

    func unitInfoUpdated(_ notification: Notification) {
        var fullload = false
        if let info = (notification as NSNotification).userInfo as? Dictionary<String, AnyObject> {
            if let tempFullLoad = info[VeraUnitInfoFullLoad] as? Bool {
                fullload = tempFullLoad
            }
        }

        if fullload == true {
            self.room = nil
            self.scenes = nil
            self.title = nil
            self.navigationItem.leftBarButtonItem = nil
        }
        self.collectionView!.reloadData()
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        if let scenes = self.scenes {
            return scenes.count
        }
        
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SceneCell", for: indexPath) as! SceneCell
    
        if (indexPath as NSIndexPath).row < self.scenes?.count {
            let scene = self.scenes![(indexPath as NSIndexPath).row]
            cell.scene = scene
            cell.setup()
        }
        
        return cell as UICollectionViewCell
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row < self.scenes?.count {
            let scene = self.scenes![(indexPath as NSIndexPath).row]
            
            AppDelegate.appDelegate().veraAPI.runSceneWithNotification(scene)
        }
    }
}
