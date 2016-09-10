//
//  AppDelegate.swift
//  Automation
//
//  Created by Scott Gruby on 10/4/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import Vera
import XCGLogger
import Locksmith
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

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



let kTabOrderDefault = "Tab Order"
let kSelectedTabDefault = "Selected Tab"
let kShowAudioTabDefault = "Show Audio Tab"
let kUsername = "username"
let kPassword = "password"

let kExcludedDevices = "Excluded Devices"
let kExcludedScenes = "Excluded Scenes"

let sTimeForCheck:TimeInterval = 4.0

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, UITabBarControllerDelegate {

    let log = XCGLogger.defaultInstance()
    var veraAPI = Vera.VeraAPI()
    var periodicTimer: Timer?
    var lastUnitCheck: Date?
    var handlingLogin = false
    var queryingVera = false
    var notifyView:SFSwiftNotification?
    
    class func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    var window: UIWindow?
    var initialTabViewControllers = [UIViewController]()

    func logout() {
        do {
            try Locksmith.deleteDataForUserAccount(kPassword)
        }
        catch {
            
        }
        
        do {
            try Locksmith.deleteDataForUserAccount(kUsername)
        }
        catch {
            
        }
        self.veraAPI.resetAPI()
        self.presentLogin()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        self.veraAPI.excludedDevices = UserDefaults.standard.array(forKey: kExcludedDevices) as! [Int]?
        self.veraAPI.excludedScenes = UserDefaults.standard.array(forKey: kExcludedScenes) as! [Int]?
        
        let tabbarController = self.window!.rootViewController as! UITabBarController
        tabbarController.delegate = self
        
        log.setup(.verbose, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil, fileLogLevel: .debug)

        
        let switchesStoryboard = UIStoryboard(name: "Switches", bundle: nil)
        let audioStoryboard = UIStoryboard(name: "Audio", bundle: nil)
        let scenesStoryboard = UIStoryboard(name: "Scenes", bundle: nil)
        let onStoryboard = UIStoryboard(name: "On", bundle: nil)
        let locksStoryboard = UIStoryboard(name: "Locks", bundle: nil)
        let climateStoryboard = UIStoryboard(name: "Climate", bundle: nil)
        let settingsStoryboard = UIStoryboard(name: "Settings", bundle: nil)
        
        var viewControllers = [UIViewController]()

        let switchesSplitViewController = switchesStoryboard.instantiateInitialViewController() as! UISplitViewController
        switchesSplitViewController.tabBarItem.image = UIImage(named: "lightbulb")
        switchesSplitViewController.tabBarItem.title = NSLocalizedString("SWITCHES_TITLE", comment:"")
        switchesSplitViewController.delegate = self
        switchesSplitViewController.preferredDisplayMode = .allVisible
        switchesSplitViewController.getBaseViewController().title = switchesSplitViewController.tabBarItem.title
        viewControllers.append(switchesSplitViewController)
        
        let audioSplitViewController = audioStoryboard.instantiateInitialViewController() as! UISplitViewController
        audioSplitViewController.tabBarItem.image = UIImage(named: "radio")
        audioSplitViewController.tabBarItem.title = NSLocalizedString("AUDIO_TITLE", comment:"")
        audioSplitViewController.delegate = self
        audioSplitViewController.preferredDisplayMode = .allVisible
        audioSplitViewController.getBaseViewController().title = audioSplitViewController.tabBarItem.title
        viewControllers.append(audioSplitViewController)
        
        let scenesSplitViewController = scenesStoryboard.instantiateInitialViewController() as! UISplitViewController
        scenesSplitViewController.tabBarItem.image = UIImage(named: "scene")
        scenesSplitViewController.tabBarItem.title = NSLocalizedString("SCENES_TITLE", comment:"")
        scenesSplitViewController.delegate = self
        scenesSplitViewController.preferredDisplayMode = .allVisible
        scenesSplitViewController.getBaseViewController().title = scenesSplitViewController.tabBarItem.title
        viewControllers.append(scenesSplitViewController)
        
        if let onViewController = onStoryboard.instantiateInitialViewController() {
            onViewController.tabBarItem.image = UIImage(named: "power")
            onViewController.tabBarItem.title = NSLocalizedString("ON_TITLE", comment:"")
            onViewController.getBaseViewController().title = onViewController.tabBarItem.title
            viewControllers.append(onViewController)
        }
        
        if let locksViewController = locksStoryboard.instantiateInitialViewController() {
            locksViewController.tabBarItem.image = UIImage(named: "lock")
            locksViewController.tabBarItem.title = NSLocalizedString("LOCK_TITLE", comment:"")
            locksViewController.getBaseViewController().title = locksViewController.tabBarItem.title
            viewControllers.append(locksViewController)
        }
        
        if let climateViewController = climateStoryboard.instantiateInitialViewController() {
            climateViewController.tabBarItem.image = UIImage(named: "climate")
            climateViewController.tabBarItem.title = NSLocalizedString("CLIMATE_TITLE", comment:"")
            climateViewController.getBaseViewController().title = climateViewController.tabBarItem.title
            viewControllers.append(climateViewController)
        }
        
        if let settingsViewController = settingsStoryboard.instantiateInitialViewController() {
            settingsViewController.tabBarItem.image = UIImage(named: "gear")
            settingsViewController.tabBarItem.title = NSLocalizedString("SETTINGS_TITLE", comment:"")
            settingsViewController.getBaseViewController().title = settingsViewController.tabBarItem.title
            viewControllers.append(settingsViewController)
        }
        
        if let orderedArray = UserDefaults.standard.array(forKey: kTabOrderDefault) {
            var currentIndex = 0
            for orderedVCClass in orderedArray {
                if let className = orderedVCClass as? String {
                    for index in 0..<viewControllers.count {
                        let vcClass = (viewControllers[index] as UIViewController).getBaseViewControllerName()
                        if vcClass as String == className {
                            if currentIndex != index {
                                swap(&viewControllers[currentIndex], &viewControllers[index])
                            }
                        }
                    }
                }
                
                currentIndex += 1
            }
        }
        
        tabbarController.viewControllers = viewControllers
        
        self.initialTabViewControllers = viewControllers // Store a reference for later
        
        self.showHideAudioTab()

        self.periodicTimer = Timer.scheduledTimer(timeInterval: sTimeForCheck, target: self, selector: #selector(AppDelegate.updateVeraInfo), userInfo: nil, repeats: true)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.orientationChanged(_:)), name: NSNotification.Name.UIApplicationWillChangeStatusBarOrientation, object: nil)

        let delay = 1.0 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            self.handleLogin()
        })
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        if let timer = self.periodicTimer {
            timer.invalidate()
            self.periodicTimer = nil
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        self.periodicTimer = Timer.scheduledTimer(timeInterval: sTimeForCheck, target: self, selector: #selector(AppDelegate.updateVeraInfo), userInfo: nil, repeats: true)
        self.lastUnitCheck = nil
        updateVeraInfo()
        
        let delay = 1.0 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            self.handleLogin()
        })
    }

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
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
    
    func tabBarController(_ tabBarController: UITabBarController, didEndCustomizing viewControllers: [UIViewController], changed: Bool) {
        if (changed == true) {
            self.saveTabOrder(viewControllers)
            self.checkViewControllers()
        }
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewController.isKind(of: UINavigationController.self) {
            if let navController = viewController as? UINavigationController {
               navController.popToRootViewController(animated: true)
            }
        } else if let splitViewController = viewController as? UISplitViewController {
            if let navController = splitViewController.viewControllers.first as? UINavigationController {
                navController.popToRootViewController(animated: true)
            }
        }
    }

    func saveTabOrder (_ viewControllers: [UIViewController]) {
        var orderViewControllerArray = [String]()
        for viewController in viewControllers {
            orderViewControllerArray.append(viewController.getBaseViewControllerName() as String)
        }

        UserDefaults.standard.set(orderViewControllerArray, forKey: kTabOrderDefault)
        UserDefaults.standard.synchronize()
    }
    
    // Make sure that none of the split view controllers roll over to the more part of the tab bar controller
    func checkViewControllers () {
        if UIDevice.current.userInterfaceIdiom == .phone {
            let tabbarController = self.window!.rootViewController as! UITabBarController
            var splitViewControllerArray = [UIViewController]()
            var otherViewControllerArray = [UIViewController]()
            var rearrangeViewControllers = false
            
            for index in 0..<tabbarController.viewControllers!.count {
                let viewController = tabbarController.viewControllers![index]
                if let _ = viewController as? UISplitViewController {
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

        var passwordData:[String:String]?
        var usernameData:[String:String]?
        passwordData = Locksmith.loadDataForUserAccount(kPassword) as? [String:String]
        usernameData = Locksmith.loadDataForUserAccount(kUsername) as? [String:String]

        var password:NSString? = nil
        var username:NSString? = nil
        
        if passwordData != nil {
            password = passwordData![kPassword] as NSString?
        }

        if usernameData != nil {
            username = usernameData![kUsername] as NSString?
        }

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
        let alertController = UIAlertController(title: nil, message: NSLocalizedString("LOGIN_ALERT_TITLE", comment: ""), preferredStyle: .alert)

        let loginAction = UIAlertAction(title: NSLocalizedString("LOGIN_TITLE", comment: ""), style: .default) { (_) in
            self.handlingLogin = false
            let loginTextField = alertController.textFields![0]
            let passwordTextField = alertController.textFields![1]

            let password = passwordTextField.text
            let username = loginTextField.text
            if password != nil && username != nil && password!.isEmpty == false && username!.isEmpty == false {
                let usernameData = [kUsername: username!]
                let passwordData = [kPassword: password!]
                do {
                    try Locksmith.deleteDataForUserAccount(kPassword)
                }
                catch {
                    
                }
                
                do {
                    try Locksmith.deleteDataForUserAccount(kUsername)
                }
                catch {
                    
                }
                try! Locksmith.saveData(usernameData, forUserAccount: kUsername)
                try! Locksmith.saveData(passwordData, forUserAccount: kPassword)
                self.handleLogin()
                
            } else {
                let delay = 1.0 * Double(NSEC_PER_SEC)
                let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time, execute: {
                    self.presentLogin()
                })
            }
            
        }
        loginAction.isEnabled = false
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("CANCEL_TITLE", comment: ""), style: .cancel) { (_) in
            self.handlingLogin = false
        }

        let domainForOnePassword = "getvera.com"
        
        let onePasswordAction = UIAlertAction(title: NSLocalizedString("ONE_PASSWORD_ACTION", comment: ""), style: .destructive) { (_) in
            
            let tabbarController = self.window!.rootViewController as! UITabBarController
            
            OnePasswordExtension.shared().findLogin(forURLString: domainForOnePassword, for: self.window!.rootViewController!,
                sender: tabbarController.tabBar) { (credentials, error) -> Void in
                    self.handlingLogin = false
                    if credentials != nil && credentials?.count > 0 {
                        let creds = credentials as? [String:String]
                        let username = creds![AppExtensionUsernameKey] as String?
                        let password = creds![AppExtensionPasswordKey] as String?
                        let usernameData = [kUsername: username!]
                        let passwordData = [kPassword: password!]

                        try! Locksmith.saveData(usernameData, forUserAccount: kUsername)
                        try! Locksmith.saveData(passwordData, forUserAccount: kPassword)
                        self.handleLogin()
                    }
                    else {
                        let delay = 1.0 * Double(NSEC_PER_SEC)
                        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
                        DispatchQueue.main.asyncAfter(deadline: time, execute: {
                            self.presentLogin()
                        })
                    }
            }

        }

        alertController.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("USERNAME_PLACEHOLDER", comment: "")
            let usernameData = Locksmith.loadDataForUserAccount(kUsername) as? [String:String]
            if usernameData != nil {
                textField.text = usernameData![kUsername]
            }
            else {
                textField.text = nil
            }
            NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: textField, queue: OperationQueue.main) { (notification) in
                loginAction.isEnabled = textField.text != ""
            }
        }
        
        alertController.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("PASSWORD_PLACEHOLDER", comment: "")
            let passwordData = Locksmith.loadDataForUserAccount(kPassword) as? [String:String]
            if passwordData != nil {
                textField.text = passwordData![kPassword]
            }
            else {
                textField.text = nil
            }
            textField.isSecureTextEntry = true
        }
        
        alertController.addAction(loginAction)
        alertController.addAction(cancelAction)
        if OnePasswordExtension.shared().isAppExtensionAvailable() {
            alertController.addAction(onePasswordAction)
        }
        
        var passwordData:[String: AnyObject]?
        var usernameData:[String: AnyObject]?
        passwordData = Locksmith.loadDataForUserAccount(kPassword) as? [String:String]
        usernameData = Locksmith.loadDataForUserAccount(kUsername) as? [String:String]
        if passwordData != nil && usernameData != nil {
            loginAction.isEnabled = true
        }
        let tabbarController = self.window!.rootViewController as! UITabBarController
        tabbarController.present(alertController, animated: true, completion: nil)

    }
    
    func updateVeraInfo() {
        // We must have a username and password
        if self.queryingVera == true || self.veraAPI.username == nil || self.veraAPI.password == nil || (self.lastUnitCheck != nil && Date().timeIntervalSince(self.lastUnitCheck!) < sTimeForCheck) {
            if self.veraAPI.username == nil && self.veraAPI.password == nil {
                self.handleLogin()
            }
            return
        }
        
        self.queryingVera = true
        self.veraAPI.getUnitInformation{ (success, fullload) -> Void in
            self.queryingVera = false
            self.lastUnitCheck = Date()
            if success == true {
                let tabbarController = self.window!.rootViewController as! UITabBarController
                if let presentedController = tabbarController.presentedViewController {
                    presentedController.dismiss(animated: true, completion: { () -> Void in
                        
                    })
                }
                NotificationCenter.default.post(name: Notification.Name(rawValue: VeraUnitInfoUpdated), object: nil, userInfo: [VeraUnitInfoFullLoad:fullload])
            } else {
                self.log.info("Did not get unit info");
                if self.handlingLogin == false {
                    self.handleLogin()
                }
            }
        }
    }

    func showHideAudioTab() {
        let show = UserDefaults.standard.bool(forKey: kShowAudioTabDefault)
        let tabbarController = self.window!.rootViewController as! UITabBarController
        var newViewControllerArray = tabbarController.viewControllers
        if newViewControllerArray != nil {
            var indexToRemove:Int?
            for index in 0..<newViewControllerArray!.count {
                let viewController = newViewControllerArray![index]
                if viewController.getBaseViewController().isKind(of: AudioListViewController.self) {
                    indexToRemove = index
                    break
                }
            }
            
            if indexToRemove != nil && show == false {
                newViewControllerArray?.remove(at: indexToRemove!)
                tabbarController.viewControllers = newViewControllerArray
            }
            else if indexToRemove == nil && show == true {
                for viewController in self.initialTabViewControllers {
                    if viewController.getBaseViewController().isKind(of: AudioListViewController.self) {
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
    
    func setExcludedDeviceArray(_ array: [Int]) {
        if array.isEmpty {
            UserDefaults.standard.removeObject(forKey: kExcludedDevices)
        } else {
            UserDefaults.standard.set(array, forKey: kExcludedDevices)
        }
        
        UserDefaults.standard.synchronize()
        
        if self.veraAPI.excludedDevices == nil || (self.veraAPI.excludedDevices != nil && array != self.veraAPI.excludedDevices!) {
            
            self.veraAPI.excludedDevices = array
            
            var fullload = false
            
            if let _ = self.veraAPI.getVeraUnit() {
                fullload = true
            }
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: VeraUnitInfoUpdated), object: nil, userInfo: [VeraUnitInfoFullLoad:fullload])
        }
    }

    func setExcludedSceneArray(_ array: [Int]) {
        if array.isEmpty {
            UserDefaults.standard.removeObject(forKey: kExcludedScenes)
        } else {
            UserDefaults.standard.set(array, forKey: kExcludedScenes)
        }
        
        UserDefaults.standard.synchronize()

        if self.veraAPI.excludedScenes == nil || (self.veraAPI.excludedScenes != nil && array != self.veraAPI.excludedScenes!) {
            
            self.veraAPI.excludedScenes = array

            var fullload = false
            if let _ = self.veraAPI.getVeraUnit() {
                fullload = true
            }

            NotificationCenter.default.post(name: Notification.Name(rawValue: VeraUnitInfoUpdated), object: nil, userInfo: [VeraUnitInfoFullLoad:fullload])
        }
    }
    
    func orientationChanged(_ notification: Notification) {
        if (self.notifyView != nil) {
            self.notifyView!.hide()
        }
    }
    
    func showMessageWithTitle(_ title: NSString) {
        let tabbarController = self.window!.rootViewController as! UITabBarController
        _ = CGRect(x: 0, y: 0, width: tabbarController.view.frame.maxX, height: 64)
        if self.notifyView != nil {
            self.notifyView!.hide()
        }
        self.notifyView = SFSwiftNotification(viewController: tabbarController,
            title: nil,
            animationType: AnimationType.animationTypeCollision,
            direction: Direction.topToBottom,
            delegate: nil)
        self.notifyView!.backgroundColor = UIColor(red: 10.0/255.0, green: 243.0/255.0, blue: 237.0/255.0, alpha: 1.0)
        self.notifyView!.label.textColor = UIColor.black

        self.notifyView!.label.text = title as String
        self.notifyView!.animate(0)
    }

}

extension UIViewController {
    func getBaseViewController()->UIViewController {
        var viewController = self
        if let navController = viewController as? UINavigationController {
            if navController.topViewController != nil {
                viewController = navController.topViewController!
            }
        }
        
        if let splitViewController = viewController as? UISplitViewController {
            viewController = splitViewController.viewControllers.first!
        }
        
        if let navController = viewController as? UINavigationController {
            if navController.topViewController != nil {
                viewController = navController.topViewController!
            }
        }
        
        return viewController
    }
    
    func getBaseViewControllerName()->NSString {
        let baseViewController = self.getBaseViewController()
        return NSStringFromClass(type(of: baseViewController)) as NSString
    }
}


