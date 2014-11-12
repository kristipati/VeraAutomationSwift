//
//  VeraAPI.swift
//  Automation
//
//  Created by Scott Gruby on 10/5/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import Foundation
import Alamofire

public let VeraUnitInfoUpdated = "com.grubysolutions.veraautomation.infoupdated"
public let VeraUnitInfoFullLoad = "com.grubysolutions.veraautomation.infoupdated.fullload"

public class VeraAPI {
    public var username : String?
    public var password : String?
    public var excludedScenes: [Int]?
    public var excludedDevices: [Int]?
    var user : User?
    
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
        
    }
    
    func resetAPI () {
        self.username = nil
        self.password = nil
    }
    
    public func getUnitsInformationForUser(completionHandler: (success:Bool)->Void) {
        var serverNumber = 1
        if self.username != nil {
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
            completionHandler(success: false)
        }
    }
    
    private func getUnitsInformationForUser(#server: Int, completionHandler: (success: Bool) -> Void) {
        if self.username == nil {
            completionHandler(success: false)
            return;
        }
        let requestString = "https://sta\(server).mios.com/locator_json.php?username=\(self.username!)"
        Swell.info("Request: \(requestString)")
        self.requestWithActivityIndicator(.GET, URLString: requestString).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
            Swell.info("Response: \(response)")
            Swell.info("ResponseString: \(responseString)")
            if responseString != nil {
                self.user <<<< responseString!
                if let units = self.user?.units {
                    for unit in units {
                        Swell.info("Unit: \(unit)")
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
    
    public func getUnitInformation(completionHandler:(success:Bool, fullload: Bool) -> Void) {
        if let prefix = self.requestPrefix() {
            if let unit = self.getVeraUnit() {
                var requestString = prefix + "lu_sdata&timeout=10&minimumdelay=2000"

                if unit.loadtime > 0 {
                    requestString += "&loadtime=\(unit.loadtime)"
                }
                
                if unit.dataversion > 0 {
                    requestString += "&dataversion=\(unit.dataversion)"
                }
                
                Swell.info("request: \(requestString)")
                self.requestWithActivityIndicator(.GET, URLString: requestString).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                    Swell.info("Response: \(response)")
                    Swell.info("ResponseString: \(responseString)")
                    if responseString != nil {
                        var newUnit:Unit?
                        var fullload = false
                        newUnit <<<< responseString!
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
    
    func requestPrefix() -> String? {
        if let unit = self.getVeraUnit() {
            if unit.ipAddress != nil && unit.ipAddress!.isEmpty == false {
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

    func requestWithActivityIndicator(method: Alamofire.Method, URLString: URLStringConvertible, parameters: [String: AnyObject]? = nil, encoding: Alamofire.ParameterEncoding = .URL) -> Request {
        
        Swell.info("Sending request: \(URLString)")
        
        ActivityManager.addActivity()
        let request = Alamofire.request(method, URLString, parameters: parameters, encoding: encoding);
        
        var time = dispatch_time(DISPATCH_TIME_NOW, Int64(30.0 * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue(), { (_) in
            self.checkForRequestCompletion(request)
        })

        return request
    }

    func checkForRequestCompletion(request: Request) {
        if request.task.state != .Completed {
            Swell.info("request for: \(request.request) timed out")
                request.cancel()
        }
    }
    
    // Mark methods that operate on the first unit
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
            return unit.roomsWithDevices(excluded: showExcluded == true ? nil : self.excludedDevices, categories:categories)
        }
        return nil
    }
    
    public func roomsWithScenes(showExcluded: Bool = false)->[Room]? {
        if let unit = self.getVeraUnit() {
            return unit.roomsWithScenes(excluded: showExcluded == true ? nil : self.excludedScenes)
        }
        
        return nil
    }
    
    public func setDeviceStatus(device: Device, newDeviceStatus: Int?, newDeviceLevel: Int?, completionHandler:(NSError?)->Void) -> Void {

        if let prefix = self.requestPrefix() {
            if let deviceID = device.id {
                var newStatus = 0
                var newLevel = 0
                var requestString: String?
                
                if let tempStatus = newDeviceStatus {
                    requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:upnp-org:serviceId:SwitchPower1&action=SetTarget&newTargetValue=\(tempStatus)"
                }
                else if let level = newDeviceLevel {
                    requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:upnp-org:serviceId:Dimming1&action=SetLoadLevelTarget&newLoadlevelTarget=\(level)"
                }

                if requestString != nil {
                    self.requestWithActivityIndicator(.GET, URLString: requestString!).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                        completionHandler(error)
                    }
                }
            }
        }
    }

    public func runScene(scene: Scene, completionHandler:(NSError?)->Void) -> Void {
        if let prefix = self.requestPrefix() {
            if let sceneID = scene.id {

                let requestString = prefix + "lu_action&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=RunScene&SceneNum=\(sceneID)"
                
                self.requestWithActivityIndicator(.GET, URLString: requestString).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                    completionHandler(error)
                }
            }
        }
    }

    public func setAudioPower(device: Device, on: Bool, completionHandler:(NSError?)->Void) -> Void {
        if let prefix = self.requestPrefix() {
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

                self.requestWithActivityIndicator(.GET, URLString: requestString).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                    completionHandler(error)
                }
            }
        }
    }

    public func changeAudioVolume(device: Device, increase: Bool, completionHandler:(NSError?)->Void) -> Void {
        if let prefix = self.requestPrefix() {
            if let deviceID = device.id {
                var newAction = "Up"
                if increase == false {
                    newAction = "Down"
                }
                
                let requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:micasaverde-com:serviceId:Volume1&action=\(newAction)"
                
                self.requestWithActivityIndicator(.GET, URLString: requestString).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                    completionHandler(error)
                }
            }
        }
    }

    public func setAudioInput(device: Device, input: Int, completionHandler:(NSError?)->Void) -> Void {
        if let prefix = self.requestPrefix() {
            if let deviceID = device.id {
                let requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:micasaverde-com:serviceId:InputSelection1&action=Input\(input)"
                
                self.requestWithActivityIndicator(.GET, URLString: requestString).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                    completionHandler(error)
                }
            }
        }
    }

    public func setLockState(device: Device, locked: Bool, completionHandler:(NSError?)->Void) -> Void {
        if let prefix = self.requestPrefix() {
            if let deviceID = device.id {
                let requestString = prefix + "lu_action&DeviceNum=\(deviceID)&serviceId=urn:micasaverde-com:serviceId:DoorLock1&action=SetTarget&newTargetValue=\(locked == true ? 1 : 0)"
                
                self.requestWithActivityIndicator(.GET, URLString: requestString).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                    completionHandler(error)
                }
            }
        }
    }
    
    public func changeHVAC(device: Device, fanMode: Device.FanMode?, hvacMode: Device.HVACMode?, coolTemp: Int?, heatTemp: Int?, completionHandler:(NSError?)->Void) -> Void {
        if let prefix = self.requestPrefix() {
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
                    self.requestWithActivityIndicator(.GET, URLString: requestString).responseStringWithActivityIndicator { (_, response, responseString, error) -> Void in
                        completionHandler(error)
                    }
                }
            }
        }

    }
}

extension Request {
    func responseStringWithActivityIndicator(completionHandler: (NSURLRequest, NSHTTPURLResponse?, String?, NSError?) -> Void) -> Self {
        var handler: (NSURLRequest, NSHTTPURLResponse?, String?, NSError?) -> (Void) = {request, response, string, error in
            VeraAPI.ActivityManager.removeActivity()
            completionHandler(request, response, string, error)
        }
        
        return responseString(completionHandler: handler)
    }
}
