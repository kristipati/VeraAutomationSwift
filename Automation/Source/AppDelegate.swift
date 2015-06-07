//
//  AppDelegate.swift
//  Automation
//
//  Created by Scott Gruby on 10/4/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera

let kTabOrderDefault = "Tab Order"
let kSelectedTabDefault = "Selected Tab"
let kShowAudioTabDefault = "Show Audio Tab"
let kUIVersionSet = "UI Version Set"
let kUseUI5Default = "Use UI5"
let kUsername = "username"
let kPassword = "password"

let kExcludedDevices = "Excluded Devices"
let kExcludedScenes = "Excluded Scenes"

let sTimeForCheck:NSTimeInterval = 4.0

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, UITabBarControllerDelegate {

    var veraAPI = Vera.VeraAPI()
    var periodicTimer: NSTimer?
    var lastUnitCheck: NSDate?
    var handlingLogin = false
    var queryingVera = false
    var notifyView:SFSwiftNotification?
    
    class func appDelegate() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }
    
    var window: UIWindow?
    var initialTabViewControllers = [UIViewController]()

    func logout() {
        KeychainService.remove(kPassword)
        KeychainService.remove(kUsername)
        self.veraAPI.resetAPI()
        self.veraAPI.useUI5 = NSUserDefaults.standardUserDefaults().boolForKey(kUseUI5Default)
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        self.veraAPI.excludedDevices = NSUserDefaults.standardUserDefaults().arrayForKey(kExcludedDevices) as! [Int]?
        self.veraAPI.excludedScenes = NSUserDefaults.standardUserDefaults().arrayForKey(kExcludedScenes) as! [Int]?
        self.veraAPI.useUI5 = NSUserDefaults.standardUserDefaults().boolForKey(kUseUI5Default)
        
        let tabbarController = self.window!.rootViewController as! UITabBarController
        tabbarController.delegate = self
        
        let switchesStoryboard = UIStoryboard(name: "Switches", bundle: nil)
        let audioStoryboard = UIStoryboard(name: "Audio", bundle: nil)
        let scenesStoryboard = UIStoryboard(name: "Scenes", bundle: nil)
        let onStoryboard = UIStoryboard(name: "On", bundle: nil)
        let locksStoryboard = UIStoryboard(name: "Locks", bundle: nil)
        let climateStoryboard = UIStoryboard(name: "Climate", bundle: nil)
        let settingsStoryboard = UIStoryboard(name: "Settings", bundle: nil)
        
        let switchesSplitViewController = switchesStoryboard.instantiateInitialViewController() as! UISplitViewController
        switchesSplitViewController.tabBarItem.image = UIImage(named: "lightbulb")
        switchesSplitViewController.tabBarItem.title = NSLocalizedString("SWITCHES_TITLE", comment:"")
        switchesSplitViewController.delegate = self
        switchesSplitViewController.preferredDisplayMode = .AllVisible
        switchesSplitViewController.getBaseViewController().title = switchesSplitViewController.tabBarItem.title
        
        let audioSplitViewController = audioStoryboard.instantiateInitialViewController() as! UISplitViewController
        audioSplitViewController.tabBarItem.image = UIImage(named: "radio")
        audioSplitViewController.tabBarItem.title = NSLocalizedString("AUDIO_TITLE", comment:"")
        audioSplitViewController.delegate = self
        audioSplitViewController.preferredDisplayMode = .AllVisible
        audioSplitViewController.getBaseViewController().title = audioSplitViewController.tabBarItem.title
        
        let scenesSplitViewController = scenesStoryboard.instantiateInitialViewController() as! UISplitViewController
        scenesSplitViewController.tabBarItem.image = UIImage(named: "scene")
        scenesSplitViewController.tabBarItem.title = NSLocalizedString("SCENES_TITLE", comment:"")
        scenesSplitViewController.delegate = self
        scenesSplitViewController.preferredDisplayMode = .AllVisible
        scenesSplitViewController.getBaseViewController().title = scenesSplitViewController.tabBarItem.title
        
        let onViewController = onStoryboard.instantiateInitialViewController() as! UIViewController
        onViewController.tabBarItem.image = UIImage(named: "power")
        onViewController.tabBarItem.title = NSLocalizedString("ON_TITLE", comment:"")
        onViewController.getBaseViewController().title = onViewController.tabBarItem.title

        let locksViewController = locksStoryboard.instantiateInitialViewController() as! UIViewController
        locksViewController.tabBarItem.image = UIImage(named: "lock")
        locksViewController.tabBarItem.title = NSLocalizedString("LOCK_TITLE", comment:"")
        locksViewController.getBaseViewController().title = locksViewController.tabBarItem.title

        let climateViewController = climateStoryboard.instantiateInitialViewController() as! UIViewController
        climateViewController.tabBarItem.image = UIImage(named: "climate")
        climateViewController.tabBarItem.title = NSLocalizedString("CLIMATE_TITLE", comment:"")
        climateViewController.getBaseViewController().title = climateViewController.tabBarItem.title

        let settingsViewController = settingsStoryboard.instantiateInitialViewController() as! UIViewController
        settingsViewController.tabBarItem.image = UIImage(named: "gear")
        settingsViewController.tabBarItem.title = NSLocalizedString("SETTINGS_TITLE", comment:"")
        settingsViewController.getBaseViewController().title = settingsViewController.tabBarItem.title
        
        var viewControllers = [UIViewController]()
        viewControllers.append(switchesSplitViewController)
        viewControllers.append(audioSplitViewController)
        viewControllers.append(scenesSplitViewController)
        viewControllers.append(onViewController)
        viewControllers.append(locksViewController)
        viewControllers.append(climateViewController)
        viewControllers.append(settingsViewController)
        
        if let orderedArray = NSUserDefaults.standardUserDefaults().arrayForKey(kTabOrderDefault) {
            var currentIndex = 0
            for orderedVCClass in orderedArray {
                if let className = orderedVCClass as? String {
                    for index in 0..<viewControllers.count {
                        let vcClass = (viewControllers[index] as UIViewController).getBaseViewControllerName()
                        if vcClass == className {
                            swap(&viewControllers[currentIndex], &viewControllers[index])
                        }
                    }
                }
                
                currentIndex++
            }
        }
        
        tabbarController.viewControllers = viewControllers
        
        self.initialTabViewControllers = viewControllers // Store a reference for later
        
        self.showHideAudioTab()

        self.periodicTimer = NSTimer.scheduledTimerWithTimeInterval(sTimeForCheck, target: self, selector: "updateVeraInfo", userInfo: nil, repeats: true)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "orientationChanged:", name: UIApplicationWillChangeStatusBarOrientationNotification, object: nil)

        let delay = 1.0 * Double(NSEC_PER_SEC)
        var time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue(), {
            self.handleLogin()
        })
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        if let timer = self.periodicTimer {
            timer.invalidate()
            self.periodicTimer = nil
        }
    }

    func applicationDidEnterBackground(application: UIApplication) {
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
        self.periodicTimer = NSTimer.scheduledTimerWithTimeInterval(sTimeForCheck, target: self, selector: "updateVeraInfo", userInfo: nil, repeats: true)
        self.lastUnitCheck = nil
        updateVeraInfo()
        
        let delay = 1.0 * Double(NSEC_PER_SEC)
        var time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue(), {
            self.handleLogin()
        })
    }

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController!, ontoPrimaryViewController primaryViewController:UIViewController!) -> Bool {
        if let secondaryAsNavController = secondaryViewController as? UINavigationController {
            if let topAsDetailController = secondaryAsNavController.topViewController as? SwitchesViewController {
                if topAsDetailController.room == nil {
                    // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
                    return true
                }
            }
            else if let topAsDetailController = secondaryAsNavController.topViewController as? ScenesViewController {
                if topAsDetailController.room == nil {
                    // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
                    return true
                }
            }
            else if let topAsDetailController = secondaryAsNavController.topViewController as? AudioViewController {
                if topAsDetailController.room == nil {
                    // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
                    return true
                }
            }
        }
        return false
    }
    
    func tabBarController(tabBarController: UITabBarController, didEndCustomizingViewControllers viewControllers: [AnyObject], changed: Bool) {
        if (changed == true) {
            self.saveTabOrder(viewControllers as! [UIViewController])
            self.checkViewControllers()
        }
    }

    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if viewController.isKindOfClass(UINavigationController) {
            if let navController = viewController as? UINavigationController {
               navController.popToRootViewControllerAnimated(true)
            }
        } else if let splitViewController = viewController as? UISplitViewController {
            if let navController = splitViewController.viewControllers.first as? UINavigationController {
                navController.popToRootViewControllerAnimated(true)
            }
        }
    }

    func saveTabOrder (viewControllers: [UIViewController]) {
        var orderViewControllerArray = [String]()
        for viewController in viewControllers {
            orderViewControllerArray.append(viewController.getBaseViewControllerName() as String)
        }

        NSUserDefaults.standardUserDefaults().setObject(orderViewControllerArray, forKey: kTabOrderDefault)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    // Make sure that none of the split view controllers roll over to the more part of the tab bar controller
    func checkViewControllers () {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            let tabbarController = self.window!.rootViewController as! UITabBarController
            var splitViewControllerArray = [UIViewController]()
            var otherViewControllerArray = [UIViewController]()
            var rearrangeViewControllers = false
            
            for index in 0..<tabbarController.viewControllers!.count {
                let viewController = tabbarController.viewControllers![index] as! UIViewController
                if let splitViewController = viewController as? UISplitViewController {
                    if index > 3 {
                        rearrangeViewControllers = true
                    }
                    splitViewControllerArray.append(viewController)
                } else {
                    otherViewControllerArray.append(viewController)
                }
            }

            if rearrangeViewControllers {
                var newViewControllerArray = [UIViewController]()
                for vc in splitViewControllerArray {
                    newViewControllerArray.append(vc)
                }

                for vc in otherViewControllerArray {
                    newViewControllerArray.append(vc)
                }

                self.saveTabOrder(newViewControllerArray as [UIViewController])
                tabbarController.viewControllers = newViewControllerArray
            }

        }
    }

    
    // MARK: Vera API
    func handleLogin () {
        if self.handlingLogin == true {
            return
        }
        
        self.handlingLogin = true

        let uiVersionSet = NSUserDefaults.standardUserDefaults().boolForKey(kUIVersionSet)
        if uiVersionSet == false {
            // Check to see if the user selected UI5 or UI7
            let alertController = UIAlertController(title: nil, message: NSLocalizedString("SELECT_UI_VERSION", comment: ""), preferredStyle: .Alert)
            
            let ui7Action = UIAlertAction(title: NSLocalizedString("UI7_TEXT", comment: ""), style: .Default) { (_) in
                self.handlingLogin = false
                NSUserDefaults.standardUserDefaults().setBool(false, forKey: kUseUI5Default)
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: kUIVersionSet)
                NSUserDefaults.standardUserDefaults().synchronize()
            }
            let ui5Action = UIAlertAction(title: NSLocalizedString("UI5_TEXT", comment: ""), style: .Cancel) { (_) in
                self.handlingLogin = false
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: kUseUI5Default)
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: kUIVersionSet)
                NSUserDefaults.standardUserDefaults().synchronize()
                self.veraAPI.useUI5 = NSUserDefaults.standardUserDefaults().boolForKey(kUseUI5Default)
            }
            
            alertController.addAction(ui7Action)
            alertController.addAction(ui5Action)
            
            let tabbarController = self.window!.rootViewController as! UITabBarController
            tabbarController.presentViewController(alertController, animated: true, completion: nil)
            return
        }

        
        
        
        var password:NSString? = KeychainService.load(kPassword)
        var username:NSString? = KeychainService.load(kUsername)
        
        if password != nil && password!.length > 0 && username != nil && username!.length > 0 {
            veraAPI.username = username as? String
            veraAPI.password = password as? String
            
            veraAPI.getUnitsInformationForUser{ (success) -> Void in
                if success == true {
                    self.handlingLogin = false
                    self.updateVeraInfo()
                }
                else {
                    self.presentLogin()
                }
            }
        } else {
            self.presentLogin()
        }
        

    }
    
    func presentLogin() {
        let alertController = UIAlertController(title: nil, message: NSLocalizedString("LOGIN_ALERT_TITLE", comment: ""), preferredStyle: .Alert)

        let loginAction = UIAlertAction(title: NSLocalizedString("LOGIN_TITLE", comment: ""), style: .Default) { (_) in
            self.handlingLogin = false
            let loginTextField = alertController.textFields![0] as! UITextField
            let passwordTextField = alertController.textFields![1] as! UITextField

            var password = passwordTextField.text
            var username = loginTextField.text
            if password != nil && username != nil && password.isEmpty == false && username.isEmpty == false {
                KeychainService.save(kUsername, data: username)
                KeychainService.save(kPassword, data: password)
                self.handleLogin()
                
            } else {
                let delay = 1.0 * Double(NSEC_PER_SEC)
                var time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                dispatch_after(time, dispatch_get_main_queue(), {
                    self.presentLogin()
                })
            }
            
        }
        loginAction.enabled = false
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("CANCEL_TITLE", comment: ""), style: .Cancel) { (_) in
            self.handlingLogin = false
        }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = NSLocalizedString("USERNAME_PLACEHOLDER", comment: "")
            textField.text = KeychainService.load(kUsername) as? String
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                loginAction.enabled = textField.text != ""
            }
        }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = NSLocalizedString("PASSWORD_PLACEHOLDER", comment: "")
            textField.text = KeychainService.load(kPassword) as? String
            textField.secureTextEntry = true
        }
        
        alertController.addAction(loginAction)
        alertController.addAction(cancelAction)
        
        if KeychainService.load(kPassword) != nil && KeychainService.load(kUsername) != nil {
            loginAction.enabled = true
        }
        
        let tabbarController = self.window!.rootViewController as! UITabBarController
        tabbarController.presentViewController(alertController, animated: true, completion: nil)

    }
    
    func updateVeraInfo() {
        // We must have a username and password
        if self.queryingVera == true || self.veraAPI.username == nil || self.veraAPI.password == nil || (self.lastUnitCheck != nil && NSDate().timeIntervalSinceDate(self.lastUnitCheck!) < sTimeForCheck) {
            if self.veraAPI.username == nil && self.veraAPI.password == nil {
                self.handleLogin()
            }
            return
        }
        
        self.queryingVera = true
        self.veraAPI.getUnitInformation{ (success, fullload) -> Void in
            self.queryingVera = false
            self.lastUnitCheck = NSDate()
            if success == true {
                let tabbarController = self.window!.rootViewController as! UITabBarController
                if let presentedController = tabbarController.presentedViewController {
                    presentedController.dismissViewControllerAnimated(true, completion: { () -> Void in
                        
                    })
                }
                NSNotificationCenter.defaultCenter().postNotificationName(VeraUnitInfoUpdated, object: nil, userInfo: [VeraUnitInfoFullLoad:fullload])
            } else {
                Swell.info("Did not get unit info");
                if self.handlingLogin == false {
                    self.handleLogin()
                }
            }
        }
    }

    func showHideAudioTab() {
        let show = NSUserDefaults.standardUserDefaults().boolForKey(kShowAudioTabDefault)
        let tabbarController = self.window!.rootViewController as! UITabBarController
        var newViewControllerArray = tabbarController.viewControllers
        if newViewControllerArray != nil {
            var indexToRemove:Int?
            for index in 0..<newViewControllerArray!.count {
                let viewController = newViewControllerArray![index] as! UIViewController
                if viewController.getBaseViewController().isKindOfClass(AudioListViewController) {
                    indexToRemove = index
                    break
                }
            }
            
            if indexToRemove != nil && show == false {
                newViewControllerArray?.removeAtIndex(indexToRemove!)
                tabbarController.viewControllers = newViewControllerArray
            }
            else if indexToRemove == nil && show == true {
                for viewController in self.initialTabViewControllers {
                    let vc = viewController as UIViewController
                    if viewController.getBaseViewController().isKindOfClass(AudioListViewController) {
                        newViewControllerArray?.append(viewController)
                        tabbarController.viewControllers = newViewControllerArray
                        tabbarController.moreNavigationController.view.setNeedsDisplay()
                        break
                    }
                }
            }
        }

        self.checkViewControllers()
    }
    
    func setExcludedDeviceArray(array: [Int]) {
        if array.isEmpty {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(kExcludedDevices)
        } else {
            NSUserDefaults.standardUserDefaults().setObject(array, forKey: kExcludedDevices)
        }
        
        NSUserDefaults.standardUserDefaults().synchronize()
        
        if self.veraAPI.excludedDevices == nil || (self.veraAPI.excludedDevices != nil && array != self.veraAPI.excludedDevices!) {
            
            self.veraAPI.excludedDevices = array
            
            var fullload = false
            
            if let unit = self.veraAPI.getVeraUnit() {
                fullload = true
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName(VeraUnitInfoUpdated, object: nil, userInfo: [VeraUnitInfoFullLoad:fullload])
        }
    }

    func setExcludedSceneArray(array: [Int]) {
        if array.isEmpty {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(kExcludedScenes)
        } else {
            NSUserDefaults.standardUserDefaults().setObject(array, forKey: kExcludedScenes)
        }
        
        NSUserDefaults.standardUserDefaults().synchronize()

        if self.veraAPI.excludedScenes == nil || (self.veraAPI.excludedScenes != nil && array != self.veraAPI.excludedScenes!) {
            
            self.veraAPI.excludedScenes = array

            var fullload = false
            if let unit = self.veraAPI.getVeraUnit() {
                fullload = true
            }

            NSNotificationCenter.defaultCenter().postNotificationName(VeraUnitInfoUpdated, object: nil, userInfo: [VeraUnitInfoFullLoad:fullload])
        }
    }
    
    func orientationChanged(notification: NSNotification) {
        if (self.notifyView != nil) {
            self.notifyView!.hide()
        }
    }
    
    func showMessageWithTitle(title: NSString) {
        let tabbarController = self.window!.rootViewController as! UITabBarController
        let notifyFrame = CGRectMake(0, 0, CGRectGetMaxX(tabbarController.view.frame), 64)
        if self.notifyView != nil {
            self.notifyView!.hide()
        }
        self.notifyView = SFSwiftNotification(viewController: tabbarController,
            title: nil,
            animationType: AnimationType.AnimationTypeCollision,
            direction: Direction.TopToBottom,
            delegate: nil)
        self.notifyView!.backgroundColor = UIColor(red: 10.0/255.0, green: 243.0/255.0, blue: 237.0/255.0, alpha: 1.0)
        self.notifyView!.label.textColor = UIColor.blackColor()

        self.notifyView!.label.text = title as String
        self.notifyView!.animate(0)
    }

}

extension UIViewController {
    func getBaseViewController()->UIViewController {
        var viewController = self
        if let navController = viewController as? UINavigationController {
            if navController.topViewController != nil {
                viewController = navController.topViewController
            }
        }
        
        if let splitViewController = viewController as? UISplitViewController {
            viewController = splitViewController.viewControllers.first as! UIViewController
        }
        
        if let navController = viewController as? UINavigationController {
            if navController.topViewController != nil {
                viewController = navController.topViewController
            }
        }
        
        return viewController
    }
    
    func getBaseViewControllerName()->NSString {
        let baseViewController = self.getBaseViewController()
        return NSStringFromClass(baseViewController.dynamicType)
    }
}


