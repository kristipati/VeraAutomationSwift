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

// swiftlint:disable variable_name
public let VeraUnitInfoUpdated = "com.grubysolutions.veraautomation.infoupdated"
public let VeraUnitInfoFullLoad = "com.grubysolutions.veraautomation.infoupdated.fullload"
// swiftlint:enable variable_name

class VeraAPI {
    var username: String?
    var password: String?
    var excludedScenes: [Int]?
    var excludedDevices: [Int]?
    var user: VeraUser?
    var auth: VeraAuth?
    var sessionToken: String?
    var reachability: Reachability?
    var currentExternalIPAddress: String?
    var lastExternalIPAddressCheck: Date?

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

        reachability = Reachability.forLocalWiFi()
        reachability?.startNotifier()
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(notification:)), name: NSNotification.Name.reachabilityChanged, object: nil)
        getExternalIPAddress()
    }

    @objc func reachabilityChanged(notification: Notification) {
        self.log.info("Reachability Changed")
        self.lastExternalIPAddressCheck = nil
        getExternalIPAddress()
    }

    let stringParseHandler: (URLResponse, Data) throws -> String? = {response, data in
        if data.count > 0 {
            return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String?
        }

        return nil
    }

    func getExternalIPAddress () {
        if lastExternalIPAddressCheck != nil && currentExternalIPAddress != nil && Date().timeIntervalSince(lastExternalIPAddressCheck!) < 300 {
            return
        }

        let requestString = "https://ip.gruby.com"
        HTTP.request(GET: requestString).parse(using: stringParseHandler).performRequest(withCompletionQueue: .main) { [weak self] (_, result) in
            self?.log.debug("Got a result")
            switch result {
            case let .success(response, data):
                self?.log.debug("Success: \(response) data: \(String(describing: data))")
                if data != nil {
                    self?.currentExternalIPAddress = data?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    self?.log.info("External IP address: \(String(describing: self?.currentExternalIPAddress))")
                    self?.lastExternalIPAddressCheck = Date()
                }
                break

            case let .error(response, error):
                self?.log.debug("Error: \(error) - \(String(describing: response))")
                break

            case .canceled:
                break
            }
        }
    }

    func resetAPI () {
        username = nil
        password = nil
        auth = nil
        sessionToken = nil
        lastExternalIPAddressCheck = nil
    }

    func sessionTokenHeaders() -> [String: String]? {
        if let token = self.sessionToken {
            return ["MMSSession": token]
        }

        return nil
    }

    func authTokenHeaders() -> [String: String]? {
        var dict: [String:String] = [:]
        if let localAuth = self.auth, let localAuthToken = localAuth.authToken, let localAuthSigToken = localAuth.authSigToken {
            dict["MMSAuth"] = localAuthToken
            dict["MMSAuthSig"] = localAuthSigToken
        }

        if dict.isEmpty {
            return nil
        }

        return dict
    }

    fileprivate func getSessionTokenForServer(server: String, completionHandler: @escaping (_ token: String?) -> Void) {

        let req = HTTP.request(GET: "https://\(server)/info/session/token")
        if self.authTokenHeaders() != nil {
            if let theHeaders = self.authTokenHeaders() {
                for (key, value) in theHeaders {
                    req?.__objc_setValue(value, forHeaderField: key)
                }
            }
        }

        req?.parse(using: stringParseHandler).performRequest(withCompletionQueue: .main) { [weak self] (_, result) in
            guard let strongSelf = self else {return}
                strongSelf.log.debug("Got a result")
                switch result {
                case let .success(response, data):
                    strongSelf.log.debug("Success: \(response) data: \(String(describing: data))")
                    if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode / 200 == 1 {
                        completionHandler(data)
                        return
                    }

                    completionHandler(nil)

                case let .error(response, error):
                    strongSelf.log.debug("Error: \(error) - \(String(describing: response))")

                case .canceled:
                    break
                }
            }
    }

    fileprivate func getAuthenticationToken(completionhandler: @escaping (_ auth: VeraAuth?) -> Void) {
        let stringToHash = username!.lowercased() + password! + passwordSeed
        let hashedString = stringToHash.sha1()
        let requestString = "https://us-autha11.mios.com/autha/auth/username/\(self.username!.lowercased())?SHA1Password=\(hashedString)&PK_Oem=1"

        HTTP.request(GET: requestString).parseAsJSON().performRequest(withCompletionQueue: .main) { (_, result) in
            self.log.debug("Got a result")
            switch result {
            case let .success(response, json):
                self.log.debug("Success: \(response) data: \(json)")
                if json != nil {
                    var auth: VeraAuth?
                    auth = VeraAuth(json: json)
                    self.log.info("Auth response: \(json)")
                    completionhandler(auth)
                } else {
                    completionhandler(nil)
                }
                break

            case let .error(response, error):
                self.log.debug("Error: \(error) - \(String(describing: response))")
                completionhandler(nil)
                break

            case .canceled:
                completionhandler(nil)
                break
            }
        }
    }

    fileprivate func getVeraDevices(completionHandler:@escaping (_ device: String?, _ internalIP: String?, _ serverDevice: String?) -> Void) {
        if self.auth != nil && self.auth!.authToken != nil {
            if let data = Data(base64Encoded: self.auth!.authToken!, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                // swiftlint:disable force_cast
                let decodedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
                // swiftlint:enable force_cast
                var tempAuth: VeraAuth?
                if let json = try? JSON.decode(decodedString) {
                    tempAuth = VeraAuth(json: json)
                }
                if tempAuth != nil {
                    self.auth?.account = tempAuth?.account
                }
                log.info("JSON: \(decodedString)")
            }

            if self.auth?.account != nil && self.auth?.serverAccount != nil {
                let requestString = "https://\(self.auth!.serverAccount!)/account/account/account/\(self.auth!.account!)/devices"
                self.getSessionTokenForServer(server: self.auth!.serverAccount!) { (token) -> Void in

                    if token != nil {
                        let req = HTTP.request(GET: requestString)
                        req?.__objc_setValue(token!, forHeaderField: "MMSSession")

                        req?.parseAsJSON().performRequest(withCompletionQueue: .main) { (_, result) in

                                switch result {
                                case let .success(_, json):
                                    self.log.info("Response for locator: \(json)")
                                    if json != nil {
                                        self.user = VeraUser(json: json)
                                    }

                                    // Grab the device info

                                    if let unit = self.getVeraUnit() {
                                        if unit.serverDevice != nil && unit.serialNumber != nil {
                                            self.getSessionTokenForServer(server: unit.serverDevice!) { (token) -> Void in
                                                if token != nil {
                                                    let requestString = "https://\(unit.serverDevice!)/device/device/device/\(unit.serialNumber!)"

                                                    let req = HTTP.request(GET: requestString)
                                                    req?.__objc_setValue(token!, forHeaderField: "MMSSession")

                                                    req?.parseAsJSON().performRequest(withCompletionQueue: .main) { (_, result) in
                                                            switch result {
                                                                case let .success(response, json):
                                                                    self.log.debug("Success: \(response) data: \(json)")
                                                                        let tempUnit = VeraUnit(json: json)
                                                                        unit.ipAddress = tempUnit.ipAddress
                                                                        unit.externalIPAddress = tempUnit.externalIPAddress
                                                                        unit.serverRelay = tempUnit.serverRelay

                                                                        self.log.info("unit: \(unit)")
                                                                        if unit.serverRelay != nil {
                                                                            self.getSessionTokenForServer(server: unit.serverRelay!) { (token) -> Void in
                                                                                self.sessionToken = token
                                                                                self.log.info("Session token: \(String(describing: token))")
                                                                                completionHandler(nil, nil, nil)
                                                                            }
                                                                        } else {
                                                                            completionHandler(nil, nil, nil)
                                                                        }

                                                            case let .error(response, error):
                                                                self.log.debug("Error: \(error) - \(String(describing: response))")
                                                                completionHandler(nil, nil, nil)
                                                                break

                                                            case .canceled:
                                                                completionHandler(nil, nil, nil)
                                                                break
                                                            }
                                                        }
                                                } else {
                                                    completionHandler(nil, nil, nil)
                                                }
                                            }
                                        } else {
                                            completionHandler(nil, nil, nil)
                                        }
                                    } else {
                                        completionHandler(nil, nil, nil)
                                    }

                                    break

                                case let .error(response, error):
                                    self.log.debug("Error: \(error) - \(String(describing: response))")
                                    completionHandler(nil, nil, nil)
                                    break

                                case .canceled:
                                    completionHandler(nil, nil, nil)
                                    break
                                }
                            } // End completion
                    }
                }
            }
        }
    }

    func getUnitsInformationForUser(completionHandler: @escaping (_ success: Bool) -> Void) {
        if self.username != nil && self.password != nil {
            self.getAuthenticationToken { (auth) -> Void in
                self.auth = auth
                self.getVeraDevices { (_, _, _) in
                    completionHandler(self.auth != nil && self.auth?.authSigToken != nil && self.auth?.authToken != nil)
                }
            }
        } else {
            completionHandler(false)
        }
    }
    fileprivate func getUnitsInformationForUser(server: Int, completionHandler: @escaping (_ success: Bool) -> Void) {
        if self.username == nil {
            completionHandler(false)
            return
        }
        let requestString = "https://sta\(server).mios.com/locator_json.php?username=\(self.username!)"
        log.info("Request: \(requestString)")

        HTTP.request(GET: requestString).parseAsJSON().performRequest(withCompletionQueue: .main) { (_, result) in
            self.log.debug("Got a result")
            switch result {
            case let .success(response, json):
                self.log.info("Response: \(response)")
                self.log.info("ResponseString: \(json)")
                self.user = VeraUser(json: json)
                if let units = self.user?.units {
                    for unit in units {
                        self.log.info("Unit: \(unit)")
                    }
                }

                completionHandler(self.user != nil)
                break

            case let .error(response, error):
                self.log.debug("Error: \(error) - \(String(describing: response))")
                completionHandler(false)
                break

            case .canceled:
                completionHandler(false)
                break
            }
        }
    }

    // We just want the first vera unit
    func getVeraUnit() -> VeraUnit? {
        return self.user?.units?.first
    }

    func requestPrefix(localPrefix: Bool) -> String? {
        if self.sessionToken != nil {
            if let unit = self.getVeraUnit() {
                if localPrefix == true {
                    if self.reachability != nil {
                        if self.reachability!.currentReachabilityStatus().rawValue != ReachableViaWiFi.rawValue {
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

                if localPrefix == true && unit.ipAddress != nil && unit.ipAddress!.isEmpty == false {
                    return "http://\(unit.ipAddress!):3480/data_request?id="
                } else if unit.serverRelay != nil {
                    return "https://\(unit.serverRelay!)/relay/relay/relay/device/\(unit.serialNumber!)/port_3480/data_request?id="
                }
            }
        } else {
            log.info("Session token is nil in requestPrefix")
        }

        return nil
    }

    func scenesForRoom(room: VeraRoom, showExcluded: Bool = false) -> [VeraScene]? {
        if let unit = self.getVeraUnit() {
            return unit.scenesForRoom(room, excluded: showExcluded == true ? nil : self.excludedScenes)
        }

        return nil
    }

    func devicesForRoom(room: VeraRoom, showExcluded: Bool = false, categories: VeraDevice.Category...) -> [VeraDevice]? {
        if let unit = self.getVeraUnit() {
            return unit.devicesForRoom(room, excluded: showExcluded == true ? nil : self.excludedDevices, categories:categories)
        }
        return nil
    }

    func roomsWithDevices(showExcluded: Bool = false, categories: VeraDevice.Category...) -> [VeraRoom]? {
        if let unit = self.getVeraUnit() {
            return unit.roomsWithDevices(showExcluded == true ? nil : self.excludedDevices, categories:categories)
        }
        return nil
    }

    func roomsWithScenes(showExcluded: Bool = false) -> [VeraRoom]? {
        if let unit = self.getVeraUnit() {
            return unit.roomsWithScenes(showExcluded == true ? nil : self.excludedScenes)
        }

        return nil
    }

    // Mark methods that operate on the first unit
    func getUnitInformation(completionHandler:@escaping (_ success: Bool, _ fullload: Bool) -> Void) {
        self.getExternalIPAddress()
        self.getUnitInformation(useLocalServer: true) { (success, fullload) -> Void in
            if success == false {
                self.getUnitInformation(useLocalServer: false) { (success, fullload) -> Void in
                    completionHandler(success, fullload)
                }
            } else {
                completionHandler(success, fullload)
            }
        }
    }

    func getUnitInformation(useLocalServer: Bool, completionHandler: @escaping (_ success: Bool, _ fullload: Bool) -> Void) {
        if let prefix = self.requestPrefix(localPrefix: useLocalServer) {
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

                req?.parseAsJSON().performRequest(withCompletionQueue: .main) { (_, result) in
                    self.log.debug("Got a result")
                    switch result {
                    case let .success(response, json):
                        self.log.debug("Success: \(response) data: \(json)")
                        let newUnit = VeraUnit(json: json)
                        var fullload = false
                        unit.dataversion = newUnit.dataversion
                        unit.loadtime = newUnit.loadtime

                        if let tempFullload = newUnit.fullload {
                            if tempFullload == true {
                                unit.rooms = newUnit.rooms
                                unit.devices = newUnit.devices
                                unit.scenes = newUnit.scenes
                                fullload = true
                            } else {
                                unit.updateUnitInfo(newUnit)
                                fullload = false
                            }
                        }

                        self.log.info("Unit: \(unit)")

                        completionHandler(true, fullload)

                    case let .error(response, error):
                        self.log.debug("Error: \(error) - \(String(describing: response))")
                        completionHandler(false, false)
                        break

                    case .canceled:
                        completionHandler(false, false)
                        break
                    }
                }
            } else {
                completionHandler(false, false)
            }
        } else {
            completionHandler(false, false)
        }
    }

    func setDeviceStatus(device: VeraDevice, newDeviceStatus: Int?, newDeviceLevel: Int?) {
        self.setDeviceStatus(useLocalServer: true, device: device, newDeviceStatus: newDeviceStatus, newDeviceLevel: newDeviceLevel) { (error) -> Void in
            if error != nil {
                self.setDeviceStatus(useLocalServer: false, device: device, newDeviceStatus: newDeviceStatus, newDeviceLevel: newDeviceLevel) { (_) -> Void in
                }
            }
        }
    }

    func setDeviceStatus(useLocalServer: Bool, device: VeraDevice, newDeviceStatus: Int?, newDeviceLevel: Int?, completionHandler:@escaping (NSError?) -> Void) {

        if let prefix = self.requestPrefix(localPrefix: useLocalServer) {
            if let deviceID = device.id {
                var requestString: String?

                if let tempStatus = newDeviceStatus {
                    requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:upnp-org:serviceId:SwitchPower1&action=SetTarget&newTargetValue=\(tempStatus)"
                } else if let level = newDeviceLevel {
                    requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:upnp-org:serviceId:Dimming1&action=SetLoadLevelTarget&newLoadlevelTarget=\(level)"
                }

                self.executeRequestWith(string: requestString)
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }

    func runScene(scene: VeraScene) {
        self.runScene(useLocalServer: true, scene:scene) { (error) -> Void in
            if error != nil {
                self.runScene(useLocalServer: false, scene:scene) { (_) -> Void in
                }
            }
        }
    }

    func runScene(useLocalServer: Bool, scene: VeraScene, completionHandler:@escaping (NSError?) -> Void) {
        if let prefix = self.requestPrefix(localPrefix: useLocalServer) {
            if let sceneID = scene.id {

                let requestString = prefix + "lu_action&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=RunScene&SceneNum=\(sceneID)"
                self.executeRequestWith(string: requestString)
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }

    func setAudioPower(device: VeraDevice, on turnOn: Bool) {
        self.setAudioPower(useLocalServer: true, device:device, on:turnOn) { (error) -> Void in
            if error != nil {
                self.setAudioPower(useLocalServer: false, device:device, on:turnOn) { (_) -> Void in
                }
            }
        }
    }

    func setAudioPower(useLocalServer: Bool, device: VeraDevice, on turnOn: Bool, completionHandler:@escaping (NSError?) -> Void) {
        if let prefix = self.requestPrefix(localPrefix: useLocalServer) {
            if let deviceID = device.id {

                var requestString = ""

                if device.parentID != nil && device.parentID! == 0 {
                    requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:micasaverde-com:serviceId:Misc1&action="
                    if turnOn == true {
                        requestString += "AllOn"
                    } else {
                        requestString += "AllOff"
                    }
                } else {
                    requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:micasaverde-com:serviceId:SwitchPower1&action=SetTarget&newTargetValue=\(turnOn == true ? 1 : 0)"
                }
                self.executeRequestWith(string: requestString)
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }

    func changeAudioVolume(device: VeraDevice, increase: Bool) {
        self.changeAudioVolume(useLocalServer: true, device:device, increase:increase) { (error) -> Void in
            if error != nil {
                self.changeAudioVolume(useLocalServer: false, device:device, increase:increase) { (_) -> Void in
                }
            }
        }
    }

    func changeAudioVolume(useLocalServer: Bool, device: VeraDevice, increase: Bool, completionHandler:@escaping (NSError?) -> Void) {
        if let prefix = self.requestPrefix(localPrefix: useLocalServer) {
            if let deviceID = device.id {
                var newAction = "Up"
                if increase == false {
                    newAction = "Down"
                }

                let requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:micasaverde-com:serviceId:Volume1&action=\(newAction)"
                self.executeRequestWith(string: requestString)
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }

    func setAudioInput(device: VeraDevice, input: Int) {
        self.setAudioInput(useLocalServer: true, device:device, input:input) { (error) -> Void in
            if error != nil {
                self.setAudioInput(useLocalServer: false, device:device, input:input) { (_) -> Void in
                }
            }
        }
    }

    func setAudioInput(useLocalServer: Bool, device: VeraDevice, input: Int, completionHandler:@escaping (NSError?) -> Void) {
        if let prefix = self.requestPrefix(localPrefix: useLocalServer) {
            if let deviceID = device.id {
                let requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:micasaverde-com:serviceId:InputSelection1&action=Input\(input)"
                self.executeRequestWith(string: requestString)
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }

    func setLockState(device: VeraDevice, locked: Bool) {
        self.setLockState(useLocalServer: true, device:device, locked:locked) { (error) -> Void in
            if error != nil {
                self.setLockState(useLocalServer: false, device:device, locked:locked) { (_) -> Void in
                }
            }
        }
    }

    func setLockState(useLocalServer: Bool, device: VeraDevice, locked: Bool, completionHandler:@escaping (NSError?) -> Void) {
        if let prefix = self.requestPrefix(localPrefix: useLocalServer) {
            if let deviceID = device.id {
                let requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:micasaverde-com:serviceId:DoorLock1&action=SetTarget&newTargetValue=\(locked == true ? 1 : 0)"
                self.executeRequestWith(string: requestString)
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }

    func changeHVAC(device: VeraDevice, fanMode: VeraDevice.FanMode?, hvacMode: VeraDevice.HVACMode?, coolTemp: Int?, heatTemp: Int?) {
        self.changeHVAC(useLocalServer: true, device:device, fanMode:fanMode, hvacMode:hvacMode, coolTemp: coolTemp, heatTemp: heatTemp) { (error) -> Void in
            if error != nil {
                self.changeHVAC(useLocalServer: false, device:device, fanMode:fanMode, hvacMode:hvacMode, coolTemp: coolTemp, heatTemp: heatTemp) { (_) -> Void in
                }
            }
        }
    }

    // swiftlint:disable function_parameter_count
    // swiftlint:disable line_length
    func changeHVAC(useLocalServer: Bool, device: VeraDevice, fanMode: VeraDevice.FanMode?, hvacMode: VeraDevice.HVACMode?, coolTemp: Int?, heatTemp: Int?, completionHandler:@escaping (NSError?) -> Void) {
        if let prefix = self.requestPrefix(localPrefix: useLocalServer) {
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

                self.executeRequestWith(string: requestString)
            }
        } else {
            completionHandler(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }

    }
    // swiftlint:enable function_parameter_count
    // swiftlint:enable line_length

    func executeRequestWith(string: String?) {
        guard let requestString = string else {return}
        if requestString.isEmpty {return}
        let req = HTTP.request(GET: requestString)
        if self.sessionTokenHeaders() != nil {
            if let theHeaders = self.sessionTokenHeaders() {
                for (key, value) in theHeaders {
                    req?.__objc_setValue(value, forHeaderField: key)
                }
            }
        }

        req?.parse(using: stringParseHandler).performRequest(withCompletionQueue: .main) { (_, result) in
            self.log.debug("Got a result")
            switch result {
            case let .success(response, responseString):
                self.log.debug("Success: \(response) data: \(String(describing: responseString))")
                break

            case let .error(response, error):
                self.log.debug("Error: \(error) - \(String(describing: response))")
                break

            case .canceled:
                break
            }
        }
    }
}
