//
//  ScenesViewController.swift
//  Automation
//
//  Created by Scott Gruby on 11/2/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera

class ScenesViewController: UICollectionViewController {
    var room: Room?
    var scenes: [Scene]?

    override func viewDidLoad() {
        super.viewDidLoad()

        if self.room != nil {
            self.scenes = AppDelegate.appDelegate().veraAPI.scenesForRoom(self.room!)
            self.title = self.room?.name
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ScenesViewController.unitInfoUpdated(_:)), name: Vera.VeraUnitInfoUpdated, object: nil)
    }

    func unitInfoUpdated(notification: NSNotification) {
        var fullload = false
        if let info = notification.userInfo as? Dictionary<String, AnyObject> {
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

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        if let scenes = self.scenes {
            return scenes.count
        }
        
        return 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("SceneCell", forIndexPath: indexPath) as! SceneCell
    
        if indexPath.row < self.scenes?.count {
            let scene = self.scenes![indexPath.row]
            cell.scene = scene
            cell.setup()
        }
        
        return cell as UICollectionViewCell
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row < self.scenes?.count {
            let scene = self.scenes![indexPath.row]
//            Swell.info("Selected: \(scene)")
            
            AppDelegate.appDelegate().veraAPI.runSceneWithNotification(scene, completionHandler: { (error: NSError?) -> Void in
            })
        }
    }
}
