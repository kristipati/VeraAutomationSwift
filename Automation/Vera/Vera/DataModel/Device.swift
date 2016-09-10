//
//  Device.swift
//  Vera
//
//  Created by Scott Gruby on 10/21/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

open class Device: Deserializable, CustomStringConvertible {
    public enum HVACMode {
        case off
        case heat
        case cool
        case auto
    }

    public enum FanMode {
        case on
        case auto
    }

    public enum Category: Int, CustomStringConvertible {
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
    
    open var id : Int?
    open var parentID: Int?
    open var category: Category?
    var subcategory: Int?
    open var status: Int?
    open var state: Int?
    open var name: String?
    var comment: String?
    open var roomID: Int?
    var armed: Bool?
    open var temperature: Double?
    open var humidity: Int?
    open var batteryLevel: Int?
    var pinCodes: String?
    open var locked: Bool?
    var tripped: Bool?
    var lastTripped: String?
    open var level: Int?
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
    open var heatTemperatureSetPoint: Double?
    open var coolTemperatureSetPoint: Double?
    open var hvacMode: HVACMode?
    open var fanMode: FanMode?
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
                    if deviceName.range(of: "audio", options: .caseInsensitive) != nil {
                        category = .audio
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
        humidity <-- data["humidity"]
        batteryLevel <-- data["batterylevel"]
        pinCodes <-- data["pincodes"]
        
        let temp: String? = data["temperature"] as! String?
        if temp != nil {
            temperature = Double(temp!)
        }

        heatTemperatureSetPoint <-- data["heatsp"]
        coolTemperatureSetPoint <-- data["coolsp"]

        let heatTemp: String? = data["heat"] as! String?
        if heatTemp != nil {
            heatTemperatureSetPoint = Double(heatTemp!)
        }

        let coolTemp: String? = data["cool"] as! String?
        if coolTemp != nil {
            coolTemperatureSetPoint = Double(coolTemp!)
        }

        

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
        conditionSatisfied <-- data["conditionsatisfied"]
        detailedArmMode <-- data["detailedarmmode"]
        armMode <-- data["armmode"]
        hvacState <-- data["hvacstate"]
        altID <-- data["altid"]
        var mode:String?
        mode <-- data["mode"]
        if mode != nil {
            switch mode!.lowercased() {
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
        
        mode <-- data["fanmode"]
        if mode != nil {
            switch mode!.lowercased() {
            case "auto":
                fanMode = .auto
            default:
                fanMode = .on
            }
        }
    }
    
    open var description: String {
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
