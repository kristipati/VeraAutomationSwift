//
//  Device.swift
//  Vera
//
//  Created by Scott Gruby on 10/21/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

public class Device: Deserializable, CustomStringConvertible {
    public enum HVACMode {
        case Off
        case Heat
        case Cool
        case Auto
    }

    public enum FanMode {
        case On
        case Auto
    }

    public enum Category: Int, CustomStringConvertible {
        case Interface = 1
        case DimmableLight = 2
        case Switch = 3
        case Sensor = 4
        case Thermostat = 5
        case Lock = 7
        case GenericIO = 11
        case SceneController = 14
        case HumiditySensor = 16
        case TemperatureSensor = 17
        case AlarmPanel = 22
        case AlarmPartition = 23
        case Audio = 200
        
        public var description: String {
            var desc: String = ""
            
            switch self {
            case .Interface:
                desc = "Interface"
                
            case .DimmableLight:
                desc = "Dimmable Light"
                
            case .Switch:
                desc = "Switch"
                
            case .Sensor:
                desc = "Sensor"
                
            case .Thermostat:
                desc = "Thermostat"
                
            case .Lock:
                desc = "Lock"
                
            case .GenericIO:
                desc = "Generic I/O"
                
            case .SceneController:
                desc = "Scene Controller"
                
            case .HumiditySensor:
                desc = "Humidity Sensor"
                
            case .TemperatureSensor:
                desc = "Temperature Sensor"
                
            case .AlarmPanel:
                desc = "Alarm Panel"
                
            case .AlarmPartition:
                desc = "Alarm Parition"
                
            case .Audio:
                desc = "Audio"
                
            }
            
            
            return desc
        }
    }
    
    public var id : Int?
    public var parentID: Int?
    public var category: Category?
    var subcategory: Int?
    public var status: Int?
    public var state: Int?
    public var name: String?
    var comment: String?
    public var roomID: Int?
    var armed: Bool?
    public var temperature: Int?
    public var humidity: Int?
    public var batteryLevel: Int?
    var pinCodes: String?
    public var locked: Bool?
    var tripped: Bool?
    var lastTripped: String?
    public var level: Int?
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
    public var heatTemperatureSetPoint: Int?
    public var coolTemperatureSetPoint: Int?
    public var hvacMode: HVACMode?
    public var fanMode: FanMode?
    var conditionSatisfied: String?
    var detailedArmMode: String?
    var armMode: String?
    var hvacState: String?
    var altID: Int?
    
    public required init(data: [String: AnyObject]) {
        id <-- data["id"]
        parentID <-- data["parent"]
        name <-- data["name"]
        var tempCategory:Int?
        tempCategory <-- data["category"]
        if tempCategory != nil {
            category = Category(rawValue: tempCategory!)
            
            if tempCategory! == 0 {
                if let deviceName = name {
                    if deviceName.rangeOfString("audio", options: .CaseInsensitiveSearch) != nil {
                        category = .Audio
                    }
                }
            }
        }
        subcategory <-- data["subcategory"]
        status <-- data["status"]
        state <-- data["state"]
        comment <-- data["comment"]
        roomID <-- data["room"]
        armed <-- data["armed"]
        temperature <-- data["temperature"]
        humidity <-- data["humidity"]
        batteryLevel <-- data["batterylevel"]
        pinCodes <-- data["pincodes"]
        
        var tempInt: Int?
        
        tempInt <-- data["locked"]
        if let lockedState = tempInt {
            if lockedState == 1 {
                locked = true
            }
            else {
                locked = false
            }
        }
        
        tripped <-- data["tripped"]
        lastTripped <-- data["lasttrip"]
        level <-- data["level"]
        ip <-- data["ip"]
        vendorStatusCode <-- data["vendorstatuscode"]
        vendorStatusData <-- data["vendorstatusdata"]
        vendorStatus <-- data["vendorstatus"]
        memoryUsed <-- data["memoryUsed"]
        memoryFree <-- data["memoryFree"]
        memoryAvailable <-- data["memoryAvailable"]
        objectStatusMap <-- data["objectstatusmap"]
        systemVeraRestart <-- data["systemVeraRestart"]
        systemLuupRestart <-- data["systemLuupRestart"]
        heatTemperatureSetPoint <-- data["heatsp"]
        coolTemperatureSetPoint <-- data["coolsp"]
        conditionSatisfied <-- data["conditionsatisfied"]
        detailedArmMode <-- data["detailedarmmode"]
        armMode <-- data["armmode"]
        hvacState <-- data["hvacstate"]
        altID <-- data["altid"]
        var mode:String?
        mode <-- data["mode"]
        if mode != nil {
            switch mode!.lowercaseString {
            case "off":
                hvacMode = .Off
            case "heaton":
                hvacMode = .Heat
            case "coolon":
                hvacMode = .Cool
            case "autochangeover":
                hvacMode = .Auto
            default:
                hvacMode = nil
            }
        }
        
        mode <-- data["fanmode"]
        if mode != nil {
            switch mode!.lowercaseString {
            case "auto":
                fanMode = .Auto
            default:
                fanMode = .On
            }
        }
    }
    
    public var description: String {
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
