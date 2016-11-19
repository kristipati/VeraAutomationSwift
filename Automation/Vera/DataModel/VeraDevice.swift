//
//  Device.swift
//  Vera
//
//  Created by Scott Gruby on 10/21/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import PMJSON

class VeraDevice: CustomStringConvertible {
    enum HVACMode {
        case off
        case heat
        case cool
        case auto
    }

    enum FanMode {
        case on
        case auto
    }

    enum Category: Int, CustomStringConvertible {
        case interface = 1
        case dimmableLight = 2
        case `switch` = 3
        case sensor = 4
        case thermostat = 5
        case lock = 7
        case genericIO = 11
        case sceneController = 14
        case humiditySensor = 16
        case temperatureSensor = 17
        case alarmPanel = 22
        case alarmPartition = 23
        case audio = 200
        
        public var description: String {
            var desc: String = ""
            
            switch self {
            case .interface:
                desc = "Interface"
                
            case .dimmableLight:
                desc = "Dimmable Light"
                
            case .switch:
                desc = "Switch"
                
            case .sensor:
                desc = "Sensor"
                
            case .thermostat:
                desc = "Thermostat"
                
            case .lock:
                desc = "Lock"
                
            case .genericIO:
                desc = "Generic I/O"
                
            case .sceneController:
                desc = "Scene Controller"
                
            case .humiditySensor:
                desc = "Humidity Sensor"
                
            case .temperatureSensor:
                desc = "Temperature Sensor"
                
            case .alarmPanel:
                desc = "Alarm Panel"
                
            case .alarmPartition:
                desc = "Alarm Parition"
                
            case .audio:
                desc = "Audio"
                
            }
            
            
            return desc
        }
    }
    
    var id : Int?
    var parentID: Int?
    var category: Category?
    var subcategory: Int?
    var status: Int?
    var state: Int?
    var name: String?
    var comment: String?
    var roomID: Int?
    var armed: Bool?
    var temperature: Double?
    var humidity: Int?
    var batteryLevel: Int?
    var pinCodes: String?
    var locked: Bool?
    var tripped: Bool?
    var lastTripped: String?
    var level: Int?
    var ip: String?
    var vendorStatusCode: String?
    var vendorStatusData: String?
    var vendorStatus: String?
    var memoryUsed: String?
    var memoryFree: String?
    var memoryAvailable: String?
    var objectStatusMap: String?
    var systemVeraRestart: String?
    var systemLuupRestart: String?
    var heatTemperatureSetPoint: Double?
    var coolTemperatureSetPoint: Double?
    var hvacMode: HVACMode?
    var fanMode: FanMode?
    var conditionSatisfied: String?
    var detailedArmMode: String?
    var armMode: String?
    var hvacState: String?
    var altID: Int?
    
    
    init(json: JSON) {
        id = json["id"]?.veraInteger
        parentID = json["parent"]?.veraInteger
        subcategory = json["subcategory"]?.veraInteger
        status = json["status"]?.veraInteger
        state = json["state"]?.veraInteger
        name = json["name"]?.string
        comment = json["comment"]?.string
        roomID = json["room"]?.veraInteger
        armed = json["armed"]?.veraBoolean
        temperature = json["temperature"]?.veraDouble
        humidity = json["humidity"]?.veraInteger
        batteryLevel = json["batterylevel"]?.veraInteger
        pinCodes = json["pincodes"]?.string
        tripped = json["tripped"]?.veraBoolean
        lastTripped = json["lasttrip"]?.string
        level = json["level"]?.veraInteger
        ip = json["ip"]?.string
        vendorStatusCode = json["vendorstatuscode"]?.string
        vendorStatusData = json["vendorstatusdata"]?.string
        vendorStatus = json["vendorstatus"]?.string
        memoryUsed = json["memoryUsed"]?.string
        memoryFree = json["memoryFree"]?.string
        memoryAvailable = json["memoryAvailable"]?.string
        objectStatusMap = json["objectstatusmap"]?.string
        systemVeraRestart = json["systemVeraRestart"]?.string
        systemLuupRestart = json["systemLuupRestart"]?.string
        heatTemperatureSetPoint = json["heatsp"]?.veraDouble
        coolTemperatureSetPoint = json["coolsp"]?.veraDouble
        
        if let heat = json["heat"]?.veraDouble {
            heatTemperatureSetPoint = heat
        }

        if let cool = json["cool"]?.veraDouble {
            coolTemperatureSetPoint = cool
        }
        
        locked = json["locked"]?.veraBoolean
        
        conditionSatisfied = json["conditionsatisfied"]?.string
        detailedArmMode = json["detailedarmmode"]?.string
        armMode = json["armmode"]?.string
        hvacState = json["hvacstate"]?.string
        altID = json["altid"]?.veraInteger
        
        if let tempCategory = json["category"]?.veraInteger {
            category = Category(rawValue: tempCategory)
            
            if tempCategory == 0 {
                if let deviceName = name {
                    if deviceName.range(of: "audio", options: .caseInsensitive) != nil {
                        category = .audio
                    }
                }
            }
        }
        
        if let mode = json["mode"]?.string {
            switch mode.lowercased() {
                case "off":
                    hvacMode = .off
                case "heaton":
                    hvacMode = .heat
                case "coolon":
                    hvacMode = .cool
                case "autochangeover":
                    hvacMode = .auto
                default:
                    hvacMode = nil
            }
        }
        
        if let mode = json["fanmode"]?.string {
            switch mode.lowercased() {
                case "auto":
                    fanMode = .auto
                default:
                    fanMode = .on
            }
        }
    }
    
    var description: String {
        var desc: String = "Name: "
        if self.name != nil {
            desc += self.name!
        }
        
        if self.id != nil {
            desc += " (\(self.id!))"
        }
        
        var categoryLabel = " - "
        if self.category != nil {
            categoryLabel += "\(self.category!)"
        }
        
        desc += "\(categoryLabel)"
        
        if let status = self.status {
            if status == 0 {
                desc += " - Off"
            } else if status == 1 {
                desc += " - On"
            }
        }

        if let locked = self.locked {
            if locked == false {
                desc += " - Unlocked"
            } else if status == 1 {
                desc += " - Locked"
            }
        }

        if let tempState = self.state {
            desc += " - State: \(tempState)"
        }
        
        if let level = self.level {
            desc += " level: \(level)"
        }
        
        return desc
    }
}
