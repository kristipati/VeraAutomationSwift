//
//  AppDelegate.swift
//  Automation
//
//  Created by Scott Gruby on 10/4/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit
import XCGLogger
import KeychainSwift
import OnePasswordExtension

let kTabOrderDefault = "Tab Order"
let kSelectedTabDefault = "Selected Tab"
let kShowAudioTabDefault = "Show Audio Tab"
let kUsername = "username"
let kPassword = "password"

let kExcludedDevices = "Excluded Devices"
let kExcludedScenes = "Excluded Scenes"

let sTimeForCheck: TimeInterval = 4.0

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, UITabBarControllerDelegate {
    let log = XCGLogger.default
    var veraAPI = VeraAPI()
    var periodicTimer: Timer?
    var lastUnitCheck: Date?
    var handlingLogin = false
    var queryingVera = false
    var notifyView: SFSwiftNotification?

    class func appDelegate() -> AppDelegate {
        // swiftlint:disable force_cast
        return UIApplication.shared.delegate as! AppDelegate
        // swiftlint:enable force_cast
    }

    var window: UIWindow?
    var initialTabViewControllers = [UIViewController]()

    func logout() {
        KeychainSwift(keyPrefix: "").clear()
        veraAPI.resetAPI()
        presentLogin()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        veraAPI.excludedDevices = UserDefaults.standard.array(forKey: kExcludedDevices) as? [Int]
        veraAPI.excludedScenes = UserDefaults.standard.array(forKey: kExcludedScenes) as? [Int]

        // swiftlint:disable force_cast
        let tabbarController = window!.rootViewController as! UITabBarController
        // swiftlint:enable force_cast
        tabbarController.delegate = self

        log.setup(level: .verbose, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil, fileLevel: .debug)

        let switchesStoryboard = UIStoryboard(name: "Switches", bundle: nil)
        let audioStoryboard = UIStoryboard(name: "Audio", bundle: nil)
        let scenesStoryboard = UIStoryboard(name: "Scenes", bundle: nil)
        let onStoryboard = UIStoryboard(name: "On", bundle: nil)
        let locksStoryboard = UIStoryboard(name: "Locks", bundle: nil)
        let climateStoryboard = UIStoryboard(name: "Climate", bundle: nil)
        let settingsStoryboard = UIStoryboard(name: "Settings", bundle: nil)

        var viewControllers = [UIViewController]()

        // swiftlint:disable force_cast
        let switchesSplitViewController = switchesStoryboard.instantiateInitialViewController() as! UISplitViewController
        // swiftlint:enable force_cast
       switchesSplitViewController.tabBarItem.image = UIImage(named: "lightbulb")
        switchesSplitViewController.tabBarItem.title = NSLocalizedString("SWITCHES_TITLE", comment:"")
        switchesSplitViewController.delegate = self
        switchesSplitViewController.preferredDisplayMode = .allVisible
        switchesSplitViewController.getBaseViewController().title = switchesSplitViewController.tabBarItem.title
        viewControllers.append(switchesSplitViewController)

        // swiftlint:disable force_cast
        let audioSplitViewController = audioStoryboard.instantiateInitialViewController() as! UISplitViewController
        // swiftlint:enable force_cast
        audioSplitViewController.tabBarItem.image = UIImage(named: "radio")
        audioSplitViewController.tabBarItem.title = NSLocalizedString("AUDIO_TITLE", comment:"")
        audioSplitViewController.delegate = self
        audioSplitViewController.preferredDisplayMode = .allVisible
        audioSplitViewController.getBaseViewController().title = audioSplitViewController.tabBarItem.title
        viewControllers.append(audioSplitViewController)

        // swiftlint:disable force_cast
        let scenesSplitViewController = scenesStoryboard.instantiateInitialViewController() as! UISplitViewController
        // swiftlint:enable force_cast
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
                        if vcClass == className && currentIndex != index {
                            viewControllers.swapAt(currentIndex, index)
                        }
                    }
                }

                currentIndex += 1
            }
        }

        tabbarController.viewControllers = viewControllers

        initialTabViewControllers = viewControllers // Store a reference for later

        showHideAudioTab()

        periodicTimer = Timer.scheduledTimer(timeInterval: sTimeForCheck, target: self, selector: #selector(AppDelegate.updateVeraInfo), userInfo: nil, repeats: true)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppDelegate.orientationChanged(notification:)),
                                               name: NSNotification.Name.UIApplicationWillChangeStatusBarOrientation,
                                               object: nil)

        let delay = 1.0 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) { [weak self] in
            self?.handleLogin()
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        periodicTimer?.invalidate()
        periodicTimer = nil
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        periodicTimer = Timer.scheduledTimer(timeInterval: sTimeForCheck, target: self, selector: #selector(AppDelegate.updateVeraInfo), userInfo: nil, repeats: true)
        lastUnitCheck = nil
        updateVeraInfo()

        let delay = 1.0 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) { [weak self] in
            self?.handleLogin()
        }
    }

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        if let secondaryAsNavController = secondaryViewController as? UINavigationController {
            if let topAsDetailController = secondaryAsNavController.topViewController as? SwitchesViewController {
                if topAsDetailController.room == nil {
                    // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
                    return true
                }
            } else if let topAsDetailController = secondaryAsNavController.topViewController as? ScenesViewController {
                if topAsDetailController.room == nil {
                    // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
                    return true
                }
            } else if let topAsDetailController = secondaryAsNavController.topViewController as? AudioViewController {
                if topAsDetailController.room == nil {
                    // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
                    return true
                }
            }
        }
        return false
    }

    func tabBarController(_ tabBarController: UITabBarController, didEndCustomizing viewControllers: [UIViewController], changed: Bool) {
        if changed == true {
            saveTabOrderWith(viewControllers: viewControllers)
            checkViewControllers()
        }
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewController.isKind(of: UINavigationController.self) {
            if let navController = viewController as? UINavigationController {
               navController.popToRootViewController(animated: true)
            }
        } else if let splitViewController = viewController as? UISplitViewController, let navController = splitViewController.viewControllers.first as? UINavigationController {
            navController.popToRootViewController(animated: true)
        }
    }

    func saveTabOrderWith (viewControllers: [UIViewController]) {
        var orderViewControllerArray = [String]()
        for viewController in viewControllers {
            orderViewControllerArray.append(viewController.getBaseViewControllerName())
        }

        UserDefaults.standard.set(orderViewControllerArray, forKey: kTabOrderDefault)
        UserDefaults.standard.synchronize()
    }

    // Make sure that none of the split view controllers roll over to the more part of the tab bar controller
    func checkViewControllers () {
        if UIDevice.current.userInterfaceIdiom == .phone {
            // swiftlint:disable force_cast
            let tabbarController = window!.rootViewController as! UITabBarController
            // swiftlint:enable force_cast
            var splitViewControllerArray = [UIViewController]()
            var otherViewControllerArray = [UIViewController]()
            var rearrangeViewControllers = false

            for index in 0..<tabbarController.viewControllers!.count {
                let viewController = tabbarController.viewControllers![index]
                if viewController as? UISplitViewController != nil {
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
                newViewControllerArray += splitViewControllerArray
                newViewControllerArray += otherViewControllerArray
                saveTabOrderWith(viewControllers: newViewControllerArray as [UIViewController])
                tabbarController.viewControllers = newViewControllerArray
            }

        }
    }

    // MARK: Vera API
    func handleLogin () {
        if handlingLogin == true {
            return
        }

        handlingLogin = true

        var password = KeychainSwift().get(kPassword)
        var username = KeychainSwift().get(kUsername)

        if password != nil && password!.characters.count > 0 && username != nil && username!.characters.count > 0 {
            veraAPI.username = username
            veraAPI.password = password

            veraAPI.getUnitsInformationForUser { [weak self] (success) -> Void in
                if let strongSelf = self {
                    if success == true {
                        strongSelf.handlingLogin = false
                        strongSelf.updateVeraInfo()
                    } else {
                        strongSelf.presentLogin()
                    }
                }
            }
        } else {
            presentLogin()
        }
    }

    func presentLogin() {
        let alertController = UIAlertController(title: nil, message: NSLocalizedString("LOGIN_ALERT_TITLE", comment: ""), preferredStyle: .alert)
        var textFieldObserver: NSObjectProtocol?

        let loginAction = UIAlertAction(title: NSLocalizedString("LOGIN_TITLE", comment: ""), style: .default) {[weak self] (_) in
            NotificationCenter.default.removeObserver(textFieldObserver as Any)
            self?.handlingLogin = false
            let loginTextField = alertController.textFields![0]
            let passwordTextField = alertController.textFields![1]

            let password = passwordTextField.text
            let username = loginTextField.text
            if password != nil && username != nil && password!.isEmpty == false && username!.isEmpty == false {
                KeychainSwift(keyPrefix: "").clear()
                KeychainSwift(keyPrefix: "").set(username!, forKey: kUsername)
                KeychainSwift(keyPrefix: "").set(password!, forKey: kPassword)

                self?.handleLogin()

            } else {
                let delay = 1.0 * Double(NSEC_PER_SEC)
                let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time) {
                    self?.presentLogin()
                }
            }
        }
        loginAction.isEnabled = false

        let cancelAction = UIAlertAction(title: NSLocalizedString("CANCEL_TITLE", comment: ""), style: .cancel) {[weak self] (_) in
            NotificationCenter.default.removeObserver(textFieldObserver as Any)
            self?.handlingLogin = false
        }

        let domainForOnePassword = "getvera.com"

        let onePasswordAction = UIAlertAction(title: NSLocalizedString("ONE_PASSWORD_ACTION", comment: ""), style: .destructive) {[weak self] (_) in
            NotificationCenter.default.removeObserver(textFieldObserver as Any)
            guard let strongSelf = self else {return}
            // swiftlint:disable force_cast
            let tabbarController = strongSelf.window!.rootViewController as! UITabBarController
            // swiftlint:enable force_cast

            OnePasswordExtension.shared().findLogin(forURLString: domainForOnePassword, for: strongSelf.window!.rootViewController!,
                sender: tabbarController.tabBar) { (credentials, _) -> Void in
                    strongSelf.handlingLogin = false
                    if let creds = credentials as? [String:String] {
                        let username = creds[AppExtensionUsernameKey] as String?
                        let password = creds[AppExtensionPasswordKey] as String?
                        KeychainSwift(keyPrefix: "").clear()
                        KeychainSwift(keyPrefix: "").set(username!, forKey: kUsername)
                        KeychainSwift(keyPrefix: "").set(password!, forKey: kPassword)
                        strongSelf.handleLogin()
                    } else {
                        let delay = 1.0 * Double(NSEC_PER_SEC)
                        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
                        DispatchQueue.main.asyncAfter(deadline: time) {
                            strongSelf.presentLogin()
                        }
                    }
            }

        }

        alertController.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("USERNAME_PLACEHOLDER", comment: "")
            textField.text = KeychainSwift(keyPrefix: "").get(kUsername)

            textFieldObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: textField, queue: OperationQueue.main) { (_) in
                loginAction.isEnabled = textField.text != ""
            }
        }

        alertController.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("PASSWORD_PLACEHOLDER", comment: "")
            textField.text = KeychainSwift(keyPrefix: "").get(kPassword)
            textField.isSecureTextEntry = true
        }

        alertController.addAction(loginAction)
        alertController.addAction(cancelAction)
        if OnePasswordExtension.shared().isAppExtensionAvailable() {
            alertController.addAction(onePasswordAction)
        }

        if KeychainSwift(keyPrefix: "").get(kUsername) != nil && KeychainSwift(keyPrefix: "").get(kPassword) != nil {
            loginAction.isEnabled = true
        }
        // swiftlint:disable force_cast
        let tabbarController = window!.rootViewController as! UITabBarController
        // swiftlint:enable force_cast
        tabbarController.present(alertController, animated: true, completion: nil)

    }

    @objc func updateVeraInfo() {
        // We must have a username and password
        if queryingVera == true || veraAPI.username == nil || veraAPI.password == nil || (lastUnitCheck != nil && Date().timeIntervalSince(lastUnitCheck!) < sTimeForCheck) {
            if veraAPI.username == nil && veraAPI.password == nil {
                handleLogin()
            }
            return
        }

        queryingVera = true
        veraAPI.getUnitInformation { [weak self] (success, fullload) in
            guard let strongSelf = self else {return}
            strongSelf.queryingVera = false
            strongSelf.lastUnitCheck = Date()
            if success == true {
                // swiftlint:disable force_cast
                let tabbarController = strongSelf.window!.rootViewController as! UITabBarController
                // swiftlint:enable force_cast
                if let presentedController = tabbarController.presentedViewController {
                    presentedController.dismiss(animated: true) {}
                }
                NotificationCenter.default.post(name: Notification.Name(rawValue: VeraUnitInfoUpdated), object: nil, userInfo: [VeraUnitInfoFullLoad: fullload])
            } else {
                strongSelf.log.info("Did not get unit info")
                if strongSelf.handlingLogin == false {
                    strongSelf.handleLogin()
                }
            }
        }
    }

    func showHideAudioTab() {
        let show = UserDefaults.standard.bool(forKey: kShowAudioTabDefault)
        // swiftlint:disable force_cast
        let tabbarController = window!.rootViewController as! UITabBarController
        // swiftlint:enable force_cast
        var newViewControllerArray = tabbarController.viewControllers
        if newViewControllerArray != nil {
            var indexToRemove: Int?
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
            } else if indexToRemove == nil && show == true {
                for viewController in initialTabViewControllers {
                    if viewController.getBaseViewController().isKind(of: AudioListViewController.self) {
                        newViewControllerArray?.append(viewController)
                        tabbarController.viewControllers = newViewControllerArray
                        tabbarController.moreNavigationController.view.setNeedsDisplay()
                        break
                    }
                }
            }
        }

        checkViewControllers()
    }

    func setExcludedDeviceArray(array: [Int]) {
        if array.isEmpty {
            UserDefaults.standard.removeObject(forKey: kExcludedDevices)
        } else {
            UserDefaults.standard.set(array, forKey: kExcludedDevices)
        }

        UserDefaults.standard.synchronize()

        if veraAPI.excludedDevices == nil || (veraAPI.excludedDevices != nil && array != veraAPI.excludedDevices!) {

            veraAPI.excludedDevices = array

            let fullload = veraAPI.getVeraUnit() != nil

            NotificationCenter.default.post(name: Notification.Name(rawValue: VeraUnitInfoUpdated), object: nil, userInfo: [VeraUnitInfoFullLoad: fullload])
        }
    }

    func setExcludedSceneArray(array: [Int]) {
        if array.isEmpty {
            UserDefaults.standard.removeObject(forKey: kExcludedScenes)
        } else {
            UserDefaults.standard.set(array, forKey: kExcludedScenes)
        }

        UserDefaults.standard.synchronize()

        if veraAPI.excludedScenes == nil || (veraAPI.excludedScenes != nil && array != veraAPI.excludedScenes!) {

            veraAPI.excludedScenes = array

            let fullload = veraAPI.getVeraUnit() != nil

            NotificationCenter.default.post(name: Notification.Name(rawValue: VeraUnitInfoUpdated), object: nil, userInfo: [VeraUnitInfoFullLoad: fullload])
        }
    }

    @objc func orientationChanged(notification: Notification) {
        if notifyView != nil {
            notifyView!.hide()
        }
    }

    func showMessageWithTitle(title: String) {
        // swiftlint:disable force_cast
        let tabbarController = window!.rootViewController as! UITabBarController
        // swiftlint:enable force_cast
        _ = CGRect(x: 0, y: 0, width: tabbarController.view.frame.maxX, height: 64)
        if notifyView != nil {
            notifyView!.hide()
        }
        notifyView = SFSwiftNotification(viewController: tabbarController,
            title: nil,
            animationType: AnimationType.animationTypeCollision,
            direction: Direction.topToBottom,
            delegate: nil)
        notifyView!.backgroundColor = UIColor(red: 10.0/255.0, green: 243.0/255.0, blue: 237.0/255.0, alpha: 1.0)
        notifyView!.label.textColor = UIColor.black

        notifyView!.label.text = title as String
        notifyView!.animate(0)
    }

}

extension UIViewController {
    func getBaseViewController() -> UIViewController {
        var viewController = self
        if let navController = viewController as? UINavigationController, navController.topViewController != nil {
            viewController = navController.topViewController!
        }

        if let splitViewController = viewController as? UISplitViewController {
            viewController = splitViewController.viewControllers.first!
        }

        if let navController = viewController as? UINavigationController, navController.topViewController != nil {
            viewController = navController.topViewController!
        }

        return viewController
    }

    func getBaseViewControllerName() -> String {
        let baseViewController = getBaseViewController()
        return String(describing: type(of: baseViewController))
    }
}
