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

public class JSON : Deserializable {
    var data:[String: AnyObject]?
    
    public required init(data: [String: AnyObject]) {
        self.data = data
    }

    private subscript(key: String) -> AnyObject? {
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

public class VeraAPI {
    public var username : String?
    public var password : String?
    public var excludedScenes: [Int]?
    public var excludedDevices: [Int]?
    public var useUI5 = false
    var user : User?
    var auth: Auth?
    var sessionToken: String?
    var manager: Alamofire.Manager?
    var reachability: Reachability?
    
    let passwordSeed = "oZ7QE6LcLJp6fiWzdqZc"
    let log = XCGLogger.defaultInstance()
    
    struct ActivityManager {
        
        static var activitiesCount = 0
        
        static func addActivity() {
            if activitiesCount == 0 {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            }
            
            activitiesCount++
        }
        
        static func removeActivity() {
            if activitiesCount > 0 {
                activitiesCount--
                
                if activitiesCount == 0 {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
            }
        }
    }

    public init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        log.setup(.Verbose, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil, fileLogLevel: .Debug)
        
        self.manager = Alamofire.Manager(configuration: configuration)
        self.reachability = Reachability.reachabilityForLocalWiFi()
        self.reachability?.startNotifier()
    }
    
    public func resetAPI () {
        self.username = nil
        self.password = nil
        self.auth = nil
        self.sessionToken = nil
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
    
    private func getSessionTokenForServer(server: String, completionHandler: (token:String?)->Void) {
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
    
    private func getAuthenticationToken(completionhandler: (auth: Auth?)->Void) {
        let stringToHash = self.username!.lowercaseString + self.password! + self.passwordSeed
        if let hashedString = stringToHash.sha1() {
            let requestString = "https://us-autha11.mios.com/autha/auth/username/\(self.username!.lowercaseString)?SHA1Password=\(hashedString)&PK_Oem=1"
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
            
        } else {
            completionhandler(auth: nil)
        }
    }

    private func getVeraDevices(completionHandler:(device: String?, internalIP: String?, serverDevice: String?)->Void) {
        if (self.auth != nil && self.auth!.authToken != nil) {
            if let data = NSData(base64EncodedString: self.auth!.authToken!, options: NSDataBase64DecodingOptions(rawValue: 0)) {
                let decodedString = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
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
                            self.log.info("Response for localtor: \(responseString)")
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
                                                if (responseString != nil) {
                                                    var tempUnit:Unit?
                                                    tempUnit <-- responseString!
                                                    if (tempUnit != nil) {
                                                        unit.ipAddress = tempUnit!.ipAddress
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
                        completionHandler(device: nil, internalIP: nil, serverDevice: nil)
                    }
                })
            }
            
        } else {
            completionHandler(device: nil, internalIP: nil, serverDevice: nil)
        }
    }

    
    public func getUnitsInformationForUser(completionHandler: (success:Bool)->Void) {
        if self.username != nil && self.password != nil {
            if self.useUI5 {
                var serverNumber = 1
                self.getUnitsInformationForUser(server: serverNumber) { (success) -> Void in
                    if success == false {
                        serverNumber++
                        self.getUnitsInformationForUser(server: serverNumber, completionHandler: { (success) -> Void in
                            completionHandler(success:success)
                        })
                        
                    } else {
                        completionHandler(success:true)
                    }
                }
            } else {
                self.getAuthenticationToken({ (auth) -> Void in
                    self.auth = auth
                    self.getVeraDevices({ (device, internalIP, serverDevice) -> Void in
                        var success = false
                        if (self.auth != nil && self.auth?.authSigToken != nil && self.auth?.authToken != nil) {
                            success = true
                        }
                        completionHandler(success: success)
                    })
                })
            }
        } else {
            completionHandler(success: false)
        }
    }
       private func getUnitsInformationForUser(server server: Int, completionHandler: (success: Bool) -> Void) {
        if self.username == nil {
            completionHandler(success: false)
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
    public func getVeraUnit() -> Unit? {
        return self.user?.units?.first
    }
    
    func requestPrefix(localPrefix: Bool) -> String? {
        if self.useUI5 == false {
            if (self.sessionToken != nil) {
                if let unit = self.getVeraUnit() {
                    if (localPrefix == true) {
                        if self.reachability != nil {
                            if (self.reachability!.currentReachabilityStatus().rawValue != ReachableViaWiFi.rawValue) {
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
        
        if let unit = self.getVeraUnit() {
            if localPrefix == true || (unit.ipAddress != nil && unit.ipAddress!.isEmpty == false) {
                return "http://\(unit.ipAddress!):3480/data_request?id="
            } else {
                if let forwardServer = unit.forwardServers?.first {
                    if forwardServer.hostName != nil && self.username != nil && self.password != nil && unit.serialNumber != nil {
                        return "https://\(forwardServer.hostName!)/\(self.username!)/\(self.password!)/\(unit.serialNumber!)/data_request?id="
                    }
                }
            }
        }

        return nil
    }

    func requestWithActivityIndicator(method: Alamofire.Method, URLString: URLStringConvertible, parameters: [String: AnyObject]? = nil, encoding: Alamofire.ParameterEncoding = .URL, headers: Dictionary<String, String>? = nil) -> Request {
        
        log.info("Sending request: \(URLString)")
        
        ActivityManager.addActivity()
        let mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: URLString.URLString)!)
        mutableURLRequest.HTTPMethod = method.rawValue
        if let theHeaders = headers {
            for (key, value) in theHeaders {
                mutableURLRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        let request = self.manager!.request(encoding.encode(mutableURLRequest, parameters: parameters).0)
        
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(30.0 * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue(), { (_) in
            self.checkForRequestCompletion(request)
        })

        return request
    }

    func checkForRequestCompletion(request: Request) {
        if request.task.state != .Completed {
            log.info("request for: \(request.request) timed out")
                request.cancel()
        }
    }

    public func scenesForRoom(room: Room, showExcluded: Bool = false)->[Scene]? {
        if let unit = self.getVeraUnit() {
            return unit.scenesForRoom(room, excluded: showExcluded == true ? nil : self.excludedScenes)
        }
        
        return nil
    }
    
    public func devicesForRoom(room: Room, showExcluded: Bool = false, categories: Device.Category...)->[Device]? {
        if let unit = self.getVeraUnit() {
            return unit.devicesForRoom(room, excluded: showExcluded == true ? nil : self.excludedDevices, categories:categories)
        }
        return nil
    }
    
    public func roomsWithDevices(showExcluded: Bool = false, categories: Device.Category...)->[Room]? {
        if let unit = self.getVeraUnit() {
            return unit.roomsWithDevices(showExcluded == true ? nil : self.excludedDevices, categories:categories)
        }
        return nil
    }
    
    public func roomsWithScenes(showExcluded: Bool = false)->[Room]? {
        if let unit = self.getVeraUnit() {
            return unit.roomsWithScenes(showExcluded == true ? nil : self.excludedScenes)
        }
        
        return nil
    }

    // Mark methods that operate on the first unit
    public func getUnitInformation(completionHandler:(success:Bool, fullload: Bool) -> Void) {
        self.getUnitInformation(true, completionHandler: { (success, fullload) -> Void in
            if (success == false) {
                self.getUnitInformation(false, completionHandler: { (success, fullload) -> Void in
                    completionHandler(success: success, fullload: fullload)
                })
            } else {
                completionHandler(success: success, fullload: fullload)
            }
        })
    }
    
    func getUnitInformation(useLocalServer:Bool, completionHandler:(success:Bool, fullload: Bool) -> Void) {
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
                completionHandler(success:false, fullload: false)
            }
        } else {
            completionHandler(success:false, fullload: false)
        }
    }

    public func setDeviceStatus(device: Device, newDeviceStatus: Int?, newDeviceLevel: Int?, completionHandler:(NSError?)->Void) -> Void {
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
    
    func setDeviceStatus(useLocalServer:Bool, device: Device, newDeviceStatus: Int?, newDeviceLevel: Int?, completionHandler:(NSError?)->Void) -> Void {

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

    public func runScene(scene: Scene, completionHandler:(NSError?)->Void) -> Void {
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
    
    func runScene(useLocalServer:Bool, scene: Scene, completionHandler:(NSError?)->Void) -> Void {
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

    public func setAudioPower(device: Device, on: Bool, completionHandler:(NSError?)->Void) -> Void {
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
    
    func setAudioPower(useLocalServer:Bool, device: Device, on: Bool, completionHandler:(NSError?)->Void) -> Void {
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

    public func changeAudioVolume(device: Device, increase: Bool, completionHandler:(NSError?)->Void) -> Void {
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
    
    func changeAudioVolume(useLocalServer:Bool, device: Device, increase: Bool, completionHandler:(NSError?)->Void) -> Void {
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

    public func setAudioInput(device: Device, input: Int, completionHandler:(NSError?)->Void) -> Void {
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
    
    func setAudioInput(useLocalServer:Bool, device: Device, input: Int, completionHandler:(NSError?)->Void) -> Void {
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

    public func setLockState(device: Device, locked: Bool, completionHandler:(NSError?)->Void) -> Void {
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
    
    func setLockState(useLocalServer:Bool, device: Device, locked: Bool, completionHandler:(NSError?)->Void) -> Void {
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

    public func changeHVAC(device: Device, fanMode: Device.FanMode?, hvacMode: Device.HVACMode?, coolTemp: Int?, heatTemp: Int?, completionHandler:(NSError?)->Void) -> Void {
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
    
    func changeHVAC(useLocalServer:Bool, device: Device, fanMode: Device.FanMode?, hvacMode: Device.HVACMode?, coolTemp: Int?, heatTemp: Int?, completionHandler:(NSError?)->Void) -> Void {
        if let prefix = self.requestPrefix(useLocalServer) {
            if let deviceID = device.id {
                var requestString = ""
                
                if let mode = fanMode {
                    var modeString = ""
                    switch mode {
                        case .Auto:
                            modeString = "Auto"
                        case .On:
                            modeString = "ContinuousOn"
                    }
                    
                    requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:upnp-org:serviceId:HVAC_FanOperatingMode1&action=SetMode&NewMode="
                    requestString += modeString
                }
                
                if let mode = hvacMode {
                    var modeString = ""

                    switch mode {
                    case .Auto:
                        modeString = "AutoChangeOver"
                    case .Off:
                        modeString = "Off"
                    case .Heat:
                        modeString = "HeatOn"
                    case .Cool:
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
    func responseData(completionHandler: (NSURLRequest?, NSHTTPURLResponse?, Result<NSData>) -> Void) -> Self {
        return response(responseSerializer: Request.dataResponseSerializer(), completionHandler: completionHandler)
    }

    func responseStringWithActivityIndicator(completionHandler: (NSURLRequest?, NSHTTPURLResponse?, String?, NSError?) -> Void) -> Self {
        let responseHandler: (NSURLRequest?, NSHTTPURLResponse?, NSData?, ErrorType?) -> (Void) = {request, urlResponse, data, error in
            VeraAPI.ActivityManager.removeActivity()
            completionHandler(request, urlResponse, NSString(data: data!, encoding: NSUTF8StringEncoding) as? String, nil)
        }
        
        return response(completionHandler: responseHandler)
    }
}
