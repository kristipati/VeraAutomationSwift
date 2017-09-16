//
//  Device.swift
//  Vera
//
//  Created by Scott Gruby on 10/21/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

class VeraDevice: CustomStringConvertible, Decodable {
    enum HVACMode {
        case off
        case heat
        case cool
        case auto
    }

    enum FanMode {
        // swiftlint:disable identifier_name
        case on
        // swiftlint:enable identifier_name
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

    var id: Int? // swiftlint:disable:this variable_name
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
    var ip: String? // swiftlint:disable:this variable_name
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

    private enum CodingKeys: String, CodingKey {
        case id // swiftlint:disable:this variable_name
        case parentID = "parent"
        case subcategory
        case status
        case state
        case name
        case comment
        case roomID = "room"
        case armed
        case temperature
        case humidity
        case batteryLevel
        case pinCodes = "pincodes"
        case tripped
        case lastTripped = "lasttrip"
        case level
        case ip // swiftlint:disable:this variable_name
        case vendorStatusCode = "vendorstatuscode"
        case vendorStatusData = "vendorstatusdata"
        case vendorStatus = "vendorstatus"
        case memoryUsed
        case memoryFree
        case memoryAvailable
        case objectStatusMap = "objectstatusmap"
        case systemVeraRestart
        case systemLuupRestart
        case heatTemperatureSetPoint = "heatsp"
        case coolTemperatureSetPoint = "coolsp"
        case locked
        case conditionSatisfied = "conditionsatisfied"
        case detailedArmMode = "detailedarmmode"
        case armMode = "armmode"
        case hvacState = "hvacstate"
        case altID = "altid"
        case heat
        case cool
        case category
        case mode
        case fanmode
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = container.decodeAsInteger(key: .id)
        self.parentID = container.decodeAsInteger(key: .parentID)
        self.subcategory = container.decodeAsInteger(key: .subcategory)
        self.status = container.decodeAsInteger(key: .status)
        self.state = container.decodeAsInteger(key: .state)
        self.name = try? container.decode(String.self, forKey: .name)
        self.comment = try? container.decode(String.self, forKey: .comment)
        self.roomID = container.decodeAsInteger(key: .roomID)
        self.armed = container.decodeAsBoolean(key: .armed)
        self.temperature = container.decodeAsDouble(key: .temperature)
        self.humidity = container.decodeAsInteger(key: .humidity)
        self.batteryLevel = container.decodeAsInteger(key: .batteryLevel)
        self.pinCodes = try? container.decode(String.self, forKey: .pinCodes)
        self.tripped = container.decodeAsBoolean(key: .tripped)
        self.lastTripped = try? container.decode(String.self, forKey: .lastTripped)
        self.level = container.decodeAsInteger(key: .level)
        self.ip = try? container.decode(String.self, forKey: .ip)
        self.vendorStatusCode = try? container.decode(String.self, forKey: .vendorStatusCode)
        self.vendorStatusData = try? container.decode(String.self, forKey: .vendorStatusData)
        self.vendorStatus = try? container.decode(String.self, forKey: .vendorStatus)
        self.memoryUsed = try? container.decode(String.self, forKey: .memoryUsed)
        self.memoryFree = try? container.decode(String.self, forKey: .memoryFree)
        self.memoryAvailable = try? container.decode(String.self, forKey: .memoryAvailable)
        self.objectStatusMap = try? container.decode(String.self, forKey: .objectStatusMap)
        self.memoryAvailable = try? container.decode(String.self, forKey: .memoryAvailable)
        self.systemVeraRestart = try? container.decode(String.self, forKey: .systemVeraRestart)
        self.systemLuupRestart = try? container.decode(String.self, forKey: .systemLuupRestart)
        self.heatTemperatureSetPoint = container.decodeAsDouble(key: .heatTemperatureSetPoint)
        self.coolTemperatureSetPoint = container.decodeAsDouble(key: .coolTemperatureSetPoint)

        if let heat = container.decodeAsDouble(key: .heat) {
            self.heatTemperatureSetPoint = heat
        }

        if let cool = container.decodeAsDouble(key: .cool) {
            self.coolTemperatureSetPoint = cool
        }

        self.locked = container.decodeAsBoolean(key: .locked)
        self.conditionSatisfied = try? container.decode(String.self, forKey: .conditionSatisfied)
        self.detailedArmMode = try? container.decode(String.self, forKey: .detailedArmMode)
        self.armMode = try? container.decode(String.self, forKey: .armMode)
        self.hvacState = try? container.decode(String.self, forKey: .hvacState)
        self.detailedArmMode = try? container.decode(String.self, forKey: .detailedArmMode)
        self.altID = container.decodeAsInteger(key: .altID)

        if let tempCategory = container.decodeAsInteger(key: .category) {
            category = Category(rawValue: tempCategory)

            if tempCategory == 0 {
                if let deviceName = name {
                    if deviceName.range(of: "audio", options: .caseInsensitive) != nil {
                        category = .audio
                    }
                }
            }
        }

        if let mode = try? container.decode(String.self, forKey: .mode) {
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

        if let mode = try? container.decode(String.self, forKey: .mode) {
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
