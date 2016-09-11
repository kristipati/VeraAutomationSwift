//
//  VeraAPI.swift
//  Automation
//
//  Created by Scott Gruby on 10/5/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import Foundation
import CryptoSwift
import XCGLogger
import PMHTTP
import JSONHelper

public let VeraUnitInfoUpdated = "com.grubysolutions.veraautomation.infoupdated"
public let VeraUnitInfoFullLoad = "com.grubysolutions.veraautomation.infoupdated.fullload"

open class JSON : Deserializable {
    var data:[String: AnyObject]?
    
    public required init(data: [String: AnyObject]) {
        self.data = data
    }
    
    fileprivate subscript(key: String) -> AnyObject? {
        get {
            if self.data != nil {
                return self.data![key]
            }
            
            return nil
        }
        set {
            if self.data != nil {
                self.data![key] = newValue
            }
        }
    }
}

open class VeraAPI {
    open var username : String?
    open var password : String?
    open var excludedScenes: [Int]?
    open var excludedDevices: [Int]?
    var user : VeraUser?
    var auth: VeraAuth?
    var sessionToken: String?
    var reachability: Reachability?
    var currentExternalIPAddress:String?
    var lastExternalIPAddressCheck:Date?
    
    let passwordSeed = "oZ7QE6LcLJp6fiWzdqZc"
    let log = XCGLogger.default
    
    public init() {
        log.setup(level: .verbose, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil, fileLevel: .debug)
        
        HTTPManager.networkActivityHandler = { active in
            UIApplication.shared.isNetworkActivityIndicatorVisible = active > 0
        }
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        HTTP.sessionConfiguration = config
        
        self.reachability = Reachability.forLocalWiFi()
        self.reachability?.startNotifier()
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(_:)), name: NSNotification.Name.reachabilityChanged, object: nil)
        self.getExternalIPAddress()
    }
    
    @objc func reachabilityChanged(_ notification: Notification) {
        self.log.info("Reachability Changed")
        self.lastExternalIPAddressCheck = nil
        getExternalIPAddress()
    }
    
    let stringParseHandler: (URLResponse, Data) throws -> String? = {response, data in
        if data.count > 0 {
            return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String
        }
        
        return nil
    }
    
    func getExternalIPAddress () {
        if self.lastExternalIPAddressCheck != nil && self.currentExternalIPAddress != nil && Date().timeIntervalSince(self.lastExternalIPAddressCheck!) < 300 {
            return
        }
        
        let requestString = "https://ip.gruby.com"
        HTTP.request(GET: requestString).parse(with: stringParseHandler).performRequest(withCompletionQueue: .main) { (task, result) in
            self.log.debug("Got a result")
            switch result {
            case let .success(response, data):
                self.log.debug("Success: \(response) data: \(data)")
                if data != nil {
                    self.currentExternalIPAddress = data?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    self.log.info("External IP address: \(self.currentExternalIPAddress)")
                    self.lastExternalIPAddressCheck = Date()
                }
                break
                
            case let .error(response, error):
                self.log.debug("Error: \(error) - \(response)")
                break
                
            case .canceled:
                break
            }
        }
    }
    
    open func resetAPI () {
        self.username = nil
        self.password = nil
        self.auth = nil
        self.sessionToken = nil
        self.lastExternalIPAddressCheck = nil
    }
    
    func sessionTokenHeaders()->Dictionary<String, String>? {
        if let token = self.sessionToken {
            return ["MMSSession":token]
        }
        
        return nil
    }
    
    func authTokenHeaders()->Dictionary<String, String>? {
        var dict: [String:String] = [:]
        if let localAuth = self.auth {
            if let localAuthToken = localAuth.authToken {
                dict["MMSAuth"] = localAuthToken
            }
            
            if let localAuthSigToken = localAuth.authSigToken {
                dict["MMSAuthSig"] = localAuthSigToken
            }
        }
        
        if dict.isEmpty {
            return nil
        }
        
        return dict
    }
    
    fileprivate func getSessionTokenForServer(_ server: String, completionHandler: @escaping (_ token:String?)->Void) {
        
        let req = HTTP.request(GET: "https://\(server)/info/session/token")
        if self.authTokenHeaders() != nil {
            if let theHeaders = self.authTokenHeaders() {
                for (key, value) in theHeaders {
                    req?.__objc_setValue(value, forHeaderField: key)
                }
            }
        }
        
        req?.parse(with: stringParseHandler).performRequest(withCompletionQueue: .main, completion: { (task, result) in
                self.log.debug("Got a result")
                switch result {
                case let .success(response, data):
                    self.log.debug("Success: \(response) data: \(data)")
                    if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                        if statusCode / 200 == 1 {
                            completionHandler(data)
                            return
                        }
                    }
                    
                    completionHandler(nil)
                    break
                    
                case let .error(response, error):
                    self.log.debug("Error: \(error) - \(response)")
                    break
                    
                case .canceled:
                    break
                }
            })
    }
    
    
    fileprivate func getAuthenticationToken(_ completionhandler: @escaping (_ auth: VeraAuth?)->Void) {
        let stringToHash = self.username!.lowercased() + self.password! + self.passwordSeed
        let hashedString = stringToHash.sha1()
        let requestString = "https://us-autha11.mios.com/autha/auth/username/\(self.username!.lowercased())?SHA1Password=\(hashedString)&PK_Oem=1"
        
        
        HTTP.request(GET: requestString).parse(with: stringParseHandler).performRequest(withCompletionQueue: .main) { (task, result) in
            self.log.debug("Got a result")
            switch result {
            case let .success(response, data):
                self.log.debug("Success: \(response) data: \(data)")
                if data != nil {
                    var auth:VeraAuth?
                    auth <-- data!
                    self.log.info("Auth response: \(data)")
                    completionhandler(auth)
                } else {
                    completionhandler(nil)
                }
                break
                
            case let .error(response, error):
                self.log.debug("Error: \(error) - \(response)")
                completionhandler(nil)
                break
                
            case .canceled:
                completionhandler(nil)
                break
            }
        }
    }
    
    fileprivate func getVeraDevices(_ completionHandler:@escaping (_ device: String?, _ internalIP: String?, _ serverDevice: String?)->Void) {
        if (self.auth != nil && self.auth!.authToken != nil) {
            if let data = Data(base64Encoded: self.auth!.authToken!, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                let decodedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String
                var tempAuth:VeraAuth?
                tempAuth <-- decodedString
                if (tempAuth != nil) {
                    self.auth?.account = tempAuth?.account
                }
                log.info("JSON: \(decodedString)")
            }
            
            if (self.auth?.account != nil && self.auth?.serverAccount != nil) {
                let requestString = "https://\(self.auth!.serverAccount!)/account/account/account/\(self.auth!.account!)/devices"
                self.getSessionTokenForServer(self.auth!.serverAccount!, completionHandler: { (token) -> Void in
                    
                    if (token != nil) {
                        let req = HTTP.request(GET: requestString)
                        req?.__objc_setValue(token!, forHeaderField: "MMSSession")
                        
                        req?.parse(with: self.stringParseHandler).performRequest(withCompletionQueue: .main, completion: { (task, result) in
                                
                                switch result {
                                case let .success(_, responseString):
                                    self.log.info("Response for locator: \(responseString)")
                                    if (responseString != nil) {
                                        var tempUser:VeraUser?
                                        tempUser <-- responseString!
                                        self.user = tempUser
                                    }
                                    
                                    // Grab the device info
                                    
                                    if let unit = self.getVeraUnit() {
                                        if (unit.serverDevice != nil && unit.serialNumber != nil) {
                                            self.getSessionTokenForServer(unit.serverDevice!, completionHandler: { (token) -> Void in
                                                if (token != nil) {
                                                    let requestString = "https://\(unit.serverDevice!)/device/device/device/\(unit.serialNumber!)"
                                                    
                                                    let req = HTTP.request(GET: requestString)
                                                    req?.__objc_setValue(token!, forHeaderField: "MMSSession")
                                                    
                                                    req?.parse(with: self.stringParseHandler).performRequest(withCompletionQueue: .main, completion: { (task, result) in
                                                            switch result {
                                                            case let .success(response, responseString):
                                                                self.log.debug("Success: \(response) data: \(responseString)")
                                                                if responseString?.isEmpty == false {
                                                                    if (responseString != nil) {
                                                                        var tempUnit:VeraUnit?
                                                                        tempUnit <-- responseString!
                                                                        if (tempUnit != nil) {
                                                                            unit.ipAddress = tempUnit!.ipAddress
                                                                            unit.externalIPAddress = tempUnit!.externalIPAddress
                                                                            unit.serverRelay = tempUnit!.serverRelay
                                                                        }
                                                                    }
                                                                    self.log.info("unit: \(unit)")
                                                                    if (unit.serverRelay != nil) {
                                                                        self.getSessionTokenForServer(unit.serverRelay!, completionHandler: { (token) -> Void in
                                                                            self.sessionToken = token
                                                                            self.log.info("Session token: \(token)")
                                                                            completionHandler(nil, nil, nil)
                                                                        })
                                                                    } else {
                                                                        completionHandler(nil, nil, nil)
                                                                    }
                                                                    
                                                                } else {
                                                                }
                                                                break
                                                                
                                                            case let .error(response, error):
                                                                self.log.debug("Error: \(error) - \(response)")
                                                                completionHandler(nil, nil, nil)
                                                                break
                                                                
                                                            case .canceled:
                                                                completionHandler(nil, nil, nil)
                                                                break
                                                            }
                                                        }
                                                    )
                                                    
                                                    
                                                } else {
                                                    completionHandler(nil, nil, nil)
                                                }
                                            })
                                        } else {
                                            completionHandler(nil, nil, nil)
                                        }
                                    } else {
                                        completionHandler(nil, nil, nil)
                                    }
                                    
                                    break
                                    
                                case let .error(response, error):
                                    self.log.debug("Error: \(error) - \(response)")
                                    completionHandler(nil, nil, nil)
                                    break
                                    
                                case .canceled:
                                    completionHandler(nil, nil, nil)
                                    break
                                }
                                
                                
                            } )// End completion
                    }
                })
            }
        }
    }
    
    
    open func getUnitsInformationForUser(_ completionHandler: @escaping (_ success:Bool)->Void) {
        if self.username != nil && self.password != nil {
            self.getAuthenticationToken({ (auth) -> Void in
                self.auth = auth
                self.getVeraDevices({ (device, internalIP, serverDevice) -> Void in
                    var success = false
                    if (self.auth != nil && self.auth?.authSigToken != nil && self.auth?.authToken != nil) {
                        success = true
                    }
                    completionHandler(success)
                })
            })
        } else {
            completionHandler(false)
        }
    }
    fileprivate func getUnitsInformationForUser(server: Int, completionHandler: @escaping (_ success: Bool) -> Void) {
        if self.username == nil {
            completionHandler(false)
            return;
        }
        let requestString = "https://sta\(server).mios.com/locator_json.php?username=\(self.username!)"
        log.info("Request: \(requestString)")
        
        HTTP.request(GET: requestString).parse(with: stringParseHandler).performRequest(withCompletionQueue: .main) { (task, result) in
            self.log.debug("Got a result")
            switch result {
            case let .success(response, responseString):
                self.log.info("Response: \(response)")
                self.log.info("ResponseString: \(responseString)")
                if responseString != nil {
                    self.user <-- responseString!
                    if let units = self.user?.units {
                        for unit in units {
                            self.log.info("Unit: \(unit)")
                        }
                    }
                }
                completionHandler(self.user != nil)
                break
                
            case let .error(response, error):
                self.log.debug("Error: \(error) - \(response)")
                completionHandler(false)
                break
                
            case .canceled:
                completionHandler(false)
                break
            }
        }
    }
    
    // We just want the first vera unit
    open func getVeraUnit() -> VeraUnit? {
        return self.user?.units?.first
    }
    
    func requestPrefix(_ localPrefix: Bool) -> String? {
        if (self.sessionToken != nil) {
            if let unit = self.getVeraUnit() {
                if (localPrefix == true) {
                    if self.reachability != nil {
                        if (self.reachability!.currentReachabilityStatus().rawValue != ReachableViaWiFi.rawValue) {
                            return nil
                        }
                    }
                }
                
                if localPrefix == true {
                    if self.currentExternalIPAddress != nil && unit.externalIPAddress != nil {
                        if self.currentExternalIPAddress! != unit.externalIPAddress! {
                            return nil
                        }
                    }
                }
                
                if (localPrefix == true && unit.ipAddress != nil && unit.ipAddress!.isEmpty == false) {
                    return "http://\(unit.ipAddress!)/port_3480/data_request?id="
                } else if unit.serverRelay != nil {
                    return "https://\(unit.serverRelay!)/relay/relay/relay/device/\(unit.serialNumber!)/port_3480/data_request?id="
                }
            }
        } else {
            log.info("Session token is nil in requestPrefix")
        }
        
        return nil
    }

    open func scenesForRoom(_ room: VeraRoom, showExcluded: Bool = false)->[VeraScene]? {
        if let unit = self.getVeraUnit() {
            return unit.scenesForRoom(room, excluded: showExcluded == true ? nil : self.excludedScenes)
        }
        
        return nil
    }
    
    open func devicesForRoom(_ room: VeraRoom, showExcluded: Bool = false, categories: VeraDevice.Category...)->[VeraDevice]? {
        if let unit = self.getVeraUnit() {
            return unit.devicesForRoom(room, excluded: showExcluded == true ? nil : self.excludedDevices, categories:categories)
        }
        return nil
    }
    
    open func roomsWithDevices(_ showExcluded: Bool = false, categories: VeraDevice.Category...)->[VeraRoom]? {
        if let unit = self.getVeraUnit() {
            return unit.roomsWithDevices(showExcluded == true ? nil : self.excludedDevices, categories:categories)
        }
        return nil
    }
    
    open func roomsWithScenes(_ showExcluded: Bool = false)->[VeraRoom]? {
        if let unit = self.getVeraUnit() {
            return unit.roomsWithScenes(showExcluded == true ? nil : self.excludedScenes)
        }
        
        return nil
    }
    
    // Mark methods that operate on the first unit
    open func getUnitInformation(_ completionHandler:@escaping (_ success:Bool, _ fullload: Bool) -> Void) {
        self.getExternalIPAddress()
        self.getUnitInformation(true, completionHandler: { (success, fullload) -> Void in
            if (success == false) {
                self.getUnitInformation(false, completionHandler: { (success, fullload) -> Void in
                    completionHandler(success, fullload)
                })
            } else {
                completionHandler(success, fullload)
            }
        })
    }
    
    func getUnitInformation(_ useLocalServer:Bool, completionHandler:@escaping (_ success:Bool, _ fullload: Bool) -> Void) {
        if let prefix = self.requestPrefix(useLocalServer) {
            if let unit = self.getVeraUnit() {
                var requestString = prefix + "lu_sdata&timeout=10&minimumdelay=2000"
                
                if unit.loadtime > 0 {
                    requestString += "&loadtime=\(unit.loadtime)"
                }
                
                if unit.dataversion > 0 {
                    requestString += "&dataversion=\(unit.dataversion)"
                }
                
                log.info("request: \(requestString)")
                
                
                let req = HTTP.request(GET: requestString)
                if self.sessionTokenHeaders() != nil {
                    if let theHeaders = self.sessionTokenHeaders() {
                        for (key, value) in theHeaders {
                            req?.__objc_setValue(value, forHeaderField: key)
                        }
                    }
                }
                
                req?.parse(with: stringParseHandler).performRequest(withCompletionQueue: .main, completion: { (task, result) in
                    self.log.debug("Got a result")
                    switch result {
                    case let .success(response, responseString):
                        self.log.debug("Success: \(response) data: \(responseString)")
                        if responseString != nil {
                            var newUnit:VeraUnit?
                            var fullload = false
                            newUnit <-- responseString!
                            if newUnit != nil {
                                unit.dataversion = newUnit!.dataversion
                                unit.loadtime = newUnit!.loadtime
                                
                                if let tempFullload = newUnit!.fullload {
                                    if tempFullload == true {
                                        unit.rooms = newUnit?.rooms
                                        unit.devices = newUnit?.devices
                                        unit.scenes = newUnit?.scenes
                                        fullload = true
                                    } else {
                                        unit.updateUnitInfo(newUnit!)
                                        fullload = false
                                    }
                                }
                            }
                            
                            self.log.info("Unit: \(unit)")
                            
                            completionHandler((newUnit != nil), fullload)
                        }
                        break
                        
                    case let .error(response, error):
                        self.log.debug("Error: \(error) - \(response)")
                        completionHandler(false, false)
                        break
                        
                    case .canceled:
                        completionHandler(false, false)
                        break
                    }
                })
            } else {
                completionHandler(false, false)
            }
        } else {
            completionHandler(false, false)
        }
    }
    
    open func setDeviceStatus(_ device: VeraDevice, newDeviceStatus: Int?, newDeviceLevel: Int?) -> Void {
        self.setDeviceStatus(true, device: device, newDeviceStatus: newDeviceStatus, newDeviceLevel: newDeviceLevel) { (error) -> Void in
            if (error != nil) {
                self.setDeviceStatus(false, device: device, newDeviceStatus: newDeviceStatus, newDeviceLevel: newDeviceLevel) { (error) -> Void in
                }
            }
        }
    }
    
    func setDeviceStatus(_ useLocalServer:Bool, device: VeraDevice, newDeviceStatus: Int?, newDeviceLevel: Int?, completionHandler:@escaping (NSError?)->Void) -> Void {
        
        if let prefix = self.requestPrefix(useLocalServer) {
            if let deviceID = device.id {
                var requestString: String?
                
                if let tempStatus = newDeviceStatus {
                    requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:upnp-org:serviceId:SwitchPower1&action=SetTarget&newTargetValue=\(tempStatus)"
                }
                else if let level = newDeviceLevel {
                    requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:upnp-org:serviceId:Dimming1&action=SetLoadLevelTarget&newLoadlevelTarget=\(level)"
                }
                
                self.executeRequest(requestString: requestString)
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }
    
    open func runScene(_ scene: VeraScene) {
        self.runScene(true, scene:scene) { (error) -> Void in
            if (error != nil) {
                self.runScene(false, scene:scene) { (error) -> Void in
                }
            }
        }
    }
    
    func runScene(_ useLocalServer:Bool, scene: VeraScene, completionHandler:@escaping (NSError?)->Void) -> Void {
        if let prefix = self.requestPrefix(useLocalServer) {
            if let sceneID = scene.id {
                
                let requestString = prefix + "lu_action&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=RunScene&SceneNum=\(sceneID)"
                self.executeRequest(requestString: requestString)
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }
    
    open func setAudioPower(_ device: VeraDevice, on: Bool) {
        self.setAudioPower(true, device:device, on:on) { (error) -> Void in
            if (error != nil) {
                self.setAudioPower(false, device:device, on:on) { (error) -> Void in
                }
            }
        }
    }
    
    func setAudioPower(_ useLocalServer:Bool, device: VeraDevice, on: Bool, completionHandler:@escaping (NSError?)->Void) -> Void {
        if let prefix = self.requestPrefix(useLocalServer) {
            if let deviceID = device.id {
                
                var requestString = ""
                
                if device.parentID != nil && device.parentID! == 0 {
                    requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:micasaverde-com:serviceId:Misc1&action="
                    if on == true {
                        requestString += "AllOn"
                    } else {
                        requestString += "AllOff"
                    }
                } else {
                    requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:micasaverde-com:serviceId:SwitchPower1&action=SetTarget&newTargetValue=\(on == true ? 1 : 0)"
                }
                self.executeRequest(requestString: requestString)
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }
    
    open func changeAudioVolume(_ device: VeraDevice, increase: Bool) {
        self.changeAudioVolume(true, device:device, increase:increase) { (error) -> Void in
            if (error != nil) {
                self.changeAudioVolume(false, device:device, increase:increase) { (error) -> Void in
                }
            }
        }
    }
    
    func changeAudioVolume(_ useLocalServer:Bool, device: VeraDevice, increase: Bool, completionHandler:@escaping (NSError?)->Void) -> Void {
        if let prefix = self.requestPrefix(useLocalServer) {
            if let deviceID = device.id {
                var newAction = "Up"
                if increase == false {
                    newAction = "Down"
                }
                
                let requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:micasaverde-com:serviceId:Volume1&action=\(newAction)"
                self.executeRequest(requestString: requestString)
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }
    
    open func setAudioInput(_ device: VeraDevice, input: Int) {
        self.setAudioInput(true, device:device, input:input) { (error) -> Void in
            if (error != nil) {
                self.setAudioInput(false, device:device, input:input) { (error) -> Void in
                }
            }
        }
    }
    
    func setAudioInput(_ useLocalServer:Bool, device: VeraDevice, input: Int, completionHandler:@escaping (NSError?)->Void) -> Void {
        if let prefix = self.requestPrefix(useLocalServer) {
            if let deviceID = device.id {
                let requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:micasaverde-com:serviceId:InputSelection1&action=Input\(input)"
                self.executeRequest(requestString: requestString)
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }
    
    open func setLockState(_ device: VeraDevice, locked: Bool) {
        self.setLockState(true, device:device, locked:locked) { (error) -> Void in
            if (error != nil) {
                self.setLockState(false, device:device, locked:locked) { (error) -> Void in
                }
            }
        }
    }
    
    func setLockState(_ useLocalServer:Bool, device: VeraDevice, locked: Bool, completionHandler:@escaping (NSError?)->Void) -> Void {
        if let prefix = self.requestPrefix(useLocalServer) {
            if let deviceID = device.id {
                let requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:micasaverde-com:serviceId:DoorLock1&action=SetTarget&newTargetValue=\(locked == true ? 1 : 0)"
                self.executeRequest(requestString: requestString)
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }
    
    open func changeHVAC(_ device: VeraDevice, fanMode: VeraDevice.FanMode?, hvacMode: VeraDevice.HVACMode?, coolTemp: Int?, heatTemp: Int?) {
        self.changeHVAC(true, device:device, fanMode:fanMode, hvacMode:hvacMode, coolTemp: coolTemp, heatTemp: heatTemp) { (error) -> Void in
            if (error != nil) {
                self.changeHVAC(false, device:device, fanMode:fanMode, hvacMode:hvacMode, coolTemp: coolTemp, heatTemp: heatTemp) { (error) -> Void in
                }
            }
        }
    }
    
    func changeHVAC(_ useLocalServer:Bool, device: VeraDevice, fanMode: VeraDevice.FanMode?, hvacMode: VeraDevice.HVACMode?, coolTemp: Int?, heatTemp: Int?, completionHandler:@escaping (NSError?)->Void) -> Void {
        if let prefix = self.requestPrefix(useLocalServer) {
            if let deviceID = device.id {
                var requestString = ""
                
                if let mode = fanMode {
                    var modeString = ""
                    switch mode {
                    case .auto:
                        modeString = "Auto"
                    case .on:
                        modeString = "ContinuousOn"
                    }
                    
                    requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:upnp-org:serviceId:HVAC_FanOperatingMode1&action=SetMode&NewMode="
                    requestString += modeString
                }
                
                if let mode = hvacMode {
                    var modeString = ""
                    
                    switch mode {
                    case .auto:
                        modeString = "AutoChangeOver"
                    case .off:
                        modeString = "Off"
                    case .heat:
                        modeString = "HeatOn"
                    case .cool:
                        modeString = "CoolOn"
                    }
                    
                    requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:upnp-org:serviceId:HVAC_UserOperatingMode1&action=SetModeTarget&NewModeTarget="
                    requestString += modeString
                }
                
                if let temp = coolTemp {
                    requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:upnp-org:serviceId:TemperatureSetpoint1_Cool&action=SetCurrentSetpoint&NewCurrentSetpoint=\(temp)"
                }
                
                if let temp = heatTemp {
                    requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:upnp-org:serviceId:TemperatureSetpoint1_Heat&action=SetCurrentSetpoint&NewCurrentSetpoint=\(temp)"
                }
                
                self.executeRequest(requestString: requestString)
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
        
    }
    
    
    func executeRequest(requestString: String?) {
        guard let requestString = requestString else {return}
        if requestString.isEmpty {return}
        let req = HTTP.request(GET: requestString)
        if self.sessionTokenHeaders() != nil {
            if let theHeaders = self.sessionTokenHeaders() {
                for (key, value) in theHeaders {
                    req?.__objc_setValue(value, forHeaderField: key)
                }
            }
        }
        
        req?.parse(with: stringParseHandler).performRequest(withCompletionQueue: .main, completion: { (task, result) in
            self.log.debug("Got a result")
            switch result {
            case let .success(response, responseString):
                self.log.debug("Success: \(response) data: \(responseString)")
                break
                
            case let .error(response, error):
                self.log.debug("Error: \(error) - \(response)")
                break
                
            case .canceled:
                break
            }
        })
    }
}
