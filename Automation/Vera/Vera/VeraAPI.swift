//
//  VeraAPI.swift
//  Automation
//
//  Created by Scott Gruby on 10/5/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import Foundation
import Alamofire
import CryptoSwift
import XCGLogger

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
    var user : User?
    var auth: Auth?
    var sessionToken: String?
    var manager: Alamofire.Manager?
    var reachability: Reachability?
    var currentExternalIPAddress:String?
    var lastExternalIPAddressCheck:Date?
    
    let passwordSeed = "oZ7QE6LcLJp6fiWzdqZc"
    let log = XCGLogger.defaultInstance()
    
    struct ActivityManager {
        
        static var activitiesCount = 0
        
        static func addActivity() {
            if activitiesCount == 0 {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            
            activitiesCount += 1
        }
        
        static func removeActivity() {
            if activitiesCount > 0 {
                activitiesCount -= 1
                
                if activitiesCount == 0 {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
        }
    }

    public init() {
        let configuration = URLSessionConfiguration.default
        log.setup(.verbose, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil, fileLogLevel: .debug)
        
        self.manager = Alamofire.Manager(configuration: configuration)
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
    
    func getExternalIPAddress () {
        if self.lastExternalIPAddressCheck != nil && self.currentExternalIPAddress != nil && Date().timeIntervalSince(self.lastExternalIPAddressCheck!) < 300 {
            return
        }

        let requestString = "http://ipv4.ipogre.com"
        self.requestWithActivityIndicator(.GET, URLString: requestString, headers:["User-Agent":"curl"]).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
            self.log.info("External IP String: \(responseString)")
            if responseString != nil {
                self.currentExternalIPAddress = responseString?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                self.log.info("External IP address: \(self.currentExternalIPAddress)")
                self.lastExternalIPAddressCheck = Date()
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
        self.requestWithActivityIndicator(.GET, URLString: "https://\(server)/info/session/token", headers: self.authTokenHeaders()).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
            self.log.info("Response with session token: \(response)")
            self.log.info("ResponseString: \(responseString)")
            
            if let statusCode = response?.statusCode {
                if statusCode / 200 == 1 {
                    completionHandler(token: responseString)
                    return
                }
            }

            completionHandler(token: nil)
        }
    }
    
    fileprivate func getAuthenticationToken(_ completionhandler: @escaping (_ auth: Auth?)->Void) {
        let stringToHash = self.username!.lowercased() + self.password! + self.passwordSeed
        let hashedString = stringToHash.sha1()
        let requestString = "https://us-autha11.mios.com/autha/auth/username/\(self.username!.lowercased())?SHA1Password=\(hashedString)&PK_Oem=1"
        self.requestWithActivityIndicator(.GET, URLString: requestString).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
            if (responseString != nil) {
                var auth:Auth?
                auth <-- responseString!
                self.log.info("Auth response: \(responseString)")
                completionhandler(auth: auth)
            } else {
                completionhandler(auth: nil)
            }
        }
    }

    fileprivate func getVeraDevices(_ completionHandler:@escaping (_ device: String?, _ internalIP: String?, _ serverDevice: String?)->Void) {
        if (self.auth != nil && self.auth!.authToken != nil) {
            if let data = Data(base64Encoded: self.auth!.authToken!, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                let decodedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String
                var tempAuth:Auth?
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
                        self.requestWithActivityIndicator(.GET, URLString: requestString, headers:["MMSSession":token!]).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                            self.log.info("Response for locator: \(responseString)")
                            if (responseString != nil) {
                                var tempUser:User?
                                tempUser <-- responseString!
                                self.user = tempUser
                            }
                            
                            // Grab the device info
                            
                            if let unit = self.getVeraUnit() {
                                if (unit.serverDevice != nil && unit.serialNumber != nil) {
                                    self.getSessionTokenForServer(unit.serverDevice!, completionHandler: { (token) -> Void in
                                        if (token != nil) {
                                            let requestString = "https://\(unit.serverDevice!)/device/device/device/\(unit.serialNumber!)"
                                            self.requestWithActivityIndicator(.GET, URLString: requestString, headers:["MMSSession":token!]).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                                                self.log.info("Response for device info: \(responseString)")
                                                if (responseString != nil) {
                                                    var tempUnit:Unit?
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
                                                        completionHandler(device: nil, internalIP: nil, serverDevice: nil)
                                                    })
                                                } else {
                                                    completionHandler(device: nil, internalIP: nil, serverDevice: nil)
                                                }
                                            }
                                        } else {
                                            completionHandler(device: nil, internalIP: nil, serverDevice: nil)
                                        }
                                    })
                                } else {
                                    completionHandler(device: nil, internalIP: nil, serverDevice: nil)
                                }
                            } else {
                                completionHandler(device: nil, internalIP: nil, serverDevice: nil)
                            }
                        }
                    } else {
                        completionHandler(nil, nil, nil)
                    }
                })
            }
            
        } else {
            completionHandler(nil, nil, nil)
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
        self.requestWithActivityIndicator(.GET, URLString: requestString).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
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
            
            completionHandler(success: self.user != nil)
        }
    }
    
    // We just want the first vera unit
    open func getVeraUnit() -> Unit? {
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

    func requestWithActivityIndicator(_ method: Alamofire.Method, URLString: URLStringConvertible, parameters: [String: AnyObject]? = nil, encoding: Alamofire.ParameterEncoding = .url, headers: Dictionary<String, String>? = nil) -> Request {
        
        log.info("Sending request: \(URLString)")
        
        ActivityManager.addActivity()
        let mutableURLRequest = NSMutableURLRequest(url: URL(string: URLString.URLString)!)
        mutableURLRequest.httpMethod = method.rawValue
        if let theHeaders = headers {
            for (key, value) in theHeaders {
                mutableURLRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        let request = self.manager!.request(encoding.encode(mutableURLRequest, parameters: parameters).0)
        
        let time = DispatchTime.now() + Double(Int64(30.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: { (_) in
            self.checkForRequestCompletion(request)
        })

        return request
    }

    func checkForRequestCompletion(_ request: Request) {
        if request.task.state != .completed {
            log.info("request for: \(request.request) timed out")
                request.cancel()
        }
    }

    open func scenesForRoom(_ room: Room, showExcluded: Bool = false)->[Scene]? {
        if let unit = self.getVeraUnit() {
            return unit.scenesForRoom(room, excluded: showExcluded == true ? nil : self.excludedScenes)
        }
        
        return nil
    }
    
    open func devicesForRoom(_ room: Room, showExcluded: Bool = false, categories: Device.Category...)->[Device]? {
        if let unit = self.getVeraUnit() {
            return unit.devicesForRoom(room, excluded: showExcluded == true ? nil : self.excludedDevices, categories:categories)
        }
        return nil
    }
    
    open func roomsWithDevices(_ showExcluded: Bool = false, categories: Device.Category...)->[Room]? {
        if let unit = self.getVeraUnit() {
            return unit.roomsWithDevices(showExcluded == true ? nil : self.excludedDevices, categories:categories)
        }
        return nil
    }
    
    open func roomsWithScenes(_ showExcluded: Bool = false)->[Room]? {
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
                self.requestWithActivityIndicator(.GET, URLString: requestString, headers: self.sessionTokenHeaders()).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                    self.log.info("Response: \(response)")
                    self.log.info("ResponseString: \(responseString)")
                    if responseString != nil {
                        var newUnit:Unit?
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
                        
                        completionHandler(success:(newUnit != nil), fullload: fullload)
                    }
                }
            } else {
                completionHandler(false, false)
            }
        } else {
            completionHandler(false, false)
        }
    }

    open func setDeviceStatus(_ device: Device, newDeviceStatus: Int?, newDeviceLevel: Int?, completionHandler:@escaping (NSError?)->Void) -> Void {
        self.setDeviceStatus(true, device: device, newDeviceStatus: newDeviceStatus, newDeviceLevel: newDeviceLevel) { (error) -> Void in
            if (error == nil) {
                completionHandler(error)
            } else {
                self.setDeviceStatus(false, device: device, newDeviceStatus: newDeviceStatus, newDeviceLevel: newDeviceLevel) { (error) -> Void in
                    completionHandler(error)
                }
            }
        }
    }
    
    func setDeviceStatus(_ useLocalServer:Bool, device: Device, newDeviceStatus: Int?, newDeviceLevel: Int?, completionHandler:@escaping (NSError?)->Void) -> Void {

        if let prefix = self.requestPrefix(useLocalServer) {
            if let deviceID = device.id {
                var requestString: String?
                
                if let tempStatus = newDeviceStatus {
                    requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:upnp-org:serviceId:SwitchPower1&action=SetTarget&newTargetValue=\(tempStatus)"
                }
                else if let level = newDeviceLevel {
                    requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:upnp-org:serviceId:Dimming1&action=SetLoadLevelTarget&newLoadlevelTarget=\(level)"
                }

                if requestString != nil {
                    self.requestWithActivityIndicator(.GET, URLString: requestString!, headers: self.sessionTokenHeaders()).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                        completionHandler(error)
                    }
                }
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }

    open func runScene(_ scene: Scene, completionHandler:@escaping (NSError?)->Void) -> Void {
        self.runScene(true, scene:scene) { (error) -> Void in
            if (error == nil) {
                completionHandler(error)
            } else {
                self.runScene(false, scene:scene) { (error) -> Void in
                    completionHandler(error)
                }
            }
        }
    }
    
    func runScene(_ useLocalServer:Bool, scene: Scene, completionHandler:@escaping (NSError?)->Void) -> Void {
        if let prefix = self.requestPrefix(useLocalServer) {
            if let sceneID = scene.id {

                let requestString = prefix + "lu_action&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=RunScene&SceneNum=\(sceneID)"
                
                self.requestWithActivityIndicator(.GET, URLString: requestString, headers: self.sessionTokenHeaders()).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                    completionHandler(error)
                }
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }

    open func setAudioPower(_ device: Device, on: Bool, completionHandler:@escaping (NSError?)->Void) -> Void {
        self.setAudioPower(true, device:device, on:on) { (error) -> Void in
            if (error == nil) {
                completionHandler(error)
            } else {
                self.setAudioPower(false, device:device, on:on) { (error) -> Void in
                    completionHandler(error)
                }
            }
        }
    }
    
    func setAudioPower(_ useLocalServer:Bool, device: Device, on: Bool, completionHandler:@escaping (NSError?)->Void) -> Void {
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

                self.requestWithActivityIndicator(.GET, URLString: requestString, headers: self.sessionTokenHeaders()).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                    completionHandler(error)
                }
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }

    open func changeAudioVolume(_ device: Device, increase: Bool, completionHandler:@escaping (NSError?)->Void) -> Void {
        self.changeAudioVolume(true, device:device, increase:increase) { (error) -> Void in
            if (error == nil) {
                completionHandler(error)
            } else {
                self.changeAudioVolume(false, device:device, increase:increase) { (error) -> Void in
                    completionHandler(error)
                }
            }
        }
    }
    
    func changeAudioVolume(_ useLocalServer:Bool, device: Device, increase: Bool, completionHandler:@escaping (NSError?)->Void) -> Void {
        if let prefix = self.requestPrefix(useLocalServer) {
            if let deviceID = device.id {
                var newAction = "Up"
                if increase == false {
                    newAction = "Down"
                }
                
                let requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:micasaverde-com:serviceId:Volume1&action=\(newAction)"
                
                self.requestWithActivityIndicator(.GET, URLString: requestString, headers: self.sessionTokenHeaders()).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                    completionHandler(error)
                }
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }

    open func setAudioInput(_ device: Device, input: Int, completionHandler:@escaping (NSError?)->Void) -> Void {
        self.setAudioInput(true, device:device, input:input) { (error) -> Void in
            if (error == nil) {
                completionHandler(error)
            } else {
                self.setAudioInput(false, device:device, input:input) { (error) -> Void in
                    completionHandler(error)
                }
            }
        }
    }
    
    func setAudioInput(_ useLocalServer:Bool, device: Device, input: Int, completionHandler:@escaping (NSError?)->Void) -> Void {
        if let prefix = self.requestPrefix(useLocalServer) {
            if let deviceID = device.id {
                let requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:micasaverde-com:serviceId:InputSelection1&action=Input\(input)"
                
                self.requestWithActivityIndicator(.GET, URLString: requestString, headers: self.sessionTokenHeaders()).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                    completionHandler(error)
                }
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }

    open func setLockState(_ device: Device, locked: Bool, completionHandler:@escaping (NSError?)->Void) -> Void {
        self.setLockState(true, device:device, locked:locked) { (error) -> Void in
            if (error == nil) {
                completionHandler(error)
            } else {
                self.setLockState(false, device:device, locked:locked) { (error) -> Void in
                    completionHandler(error)
                }
            }
        }
    }
    
    func setLockState(_ useLocalServer:Bool, device: Device, locked: Bool, completionHandler:@escaping (NSError?)->Void) -> Void {
        if let prefix = self.requestPrefix(useLocalServer) {
            if let deviceID = device.id {
                let requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:micasaverde-com:serviceId:DoorLock1&action=SetTarget&newTargetValue=\(locked == true ? 1 : 0)"
                
                self.requestWithActivityIndicator(.GET, URLString: requestString, headers: self.sessionTokenHeaders()).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                    completionHandler(error)
                }
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }

    open func changeHVAC(_ device: Device, fanMode: Device.FanMode?, hvacMode: Device.HVACMode?, coolTemp: Int?, heatTemp: Int?, completionHandler:@escaping (NSError?)->Void) -> Void {
        self.changeHVAC(true, device:device, fanMode:fanMode, hvacMode:hvacMode, coolTemp: coolTemp, heatTemp: heatTemp) { (error) -> Void in
            if (error == nil) {
                completionHandler(error)
            } else {
                self.changeHVAC(false, device:device, fanMode:fanMode, hvacMode:hvacMode, coolTemp: coolTemp, heatTemp: heatTemp) { (error) -> Void in
                    completionHandler(error)
                }
            }
        }
    }
    
    func changeHVAC(_ useLocalServer:Bool, device: Device, fanMode: Device.FanMode?, hvacMode: Device.HVACMode?, coolTemp: Int?, heatTemp: Int?, completionHandler:@escaping (NSError?)->Void) -> Void {
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
                
                if requestString.isEmpty == false {
                    self.requestWithActivityIndicator(.GET, URLString: requestString, headers: self.sessionTokenHeaders()).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                        completionHandler(error)
                    }
                }
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }

    }
}

extension Request {
//    func responseData(completionHandler: (NSURLRequest?, NSHTTPURLResponse?, Result<NSData>) -> Void) -> Self {
//        return response(responseSerializer: Request.dataResponseSerializer(), completionHandler: completionHandler)
//    }

    func responseStringWithActivityIndicator(_ completionHandler: (URLRequest?, HTTPURLResponse?, String?, NSError?) -> Void) -> Self {
        let responseHandler: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> (Void) = {request, urlResponse, data, error in
            VeraAPI.ActivityManager.removeActivity()
            completionHandler(request, urlResponse, NSString(data: data!, encoding: String.Encoding.utf8) as? String, nil)
        }
        
        return response(completionHandler: responseHandler)
    }
}
