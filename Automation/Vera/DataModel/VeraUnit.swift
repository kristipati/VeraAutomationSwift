//
//  Unit.swift
//  Automation
//
//  Created by Scott Gruby on 10/5/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import Foundation
import PMJSON

fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

class VeraUnit: CustomStringConvertible {

    var serialNumber: String?
    var firmwareVersion: String?
    var name: String?
    var ipAddress: String?
    var externalIPAddress: String?
    var users: [String]?
    var activeServer: String?
    var loadtime = 0
    var dataversion = 0
    var fullload: Bool?
    var rooms: [VeraRoom]?
    var devices: [VeraDevice]?
    var scenes: [VeraScene]?
    var serverDevice: String?
    var serverRelay: String?

    init(json: JSON) {
        serialNumber = json["serialNumber"]?.string
        firmwareVersion = json["FirmwareVersion"]?.string
        name = json["name"]?.string
        ipAddress = json["ipAddress"]?.string
//        users = try? json.mapArray("users", String.init(json:))
        activeServer = json["active_server"]?.string
        rooms = try? json.mapArray("rooms", VeraRoom.init(json:))
        fullload = json["full"]?.veraBoolean
        devices = try? json.mapArray("devices", VeraDevice.init(json:))
        scenes = try? json.mapArray("scenes", VeraScene.init(json:))
        loadtime = json["loadtime"]?.int ?? 0
        dataversion = json["dataversion"]?.int ?? 0

        if serialNumber == nil {
            serialNumber = json["PK_Device"]?.string
        }

        if ipAddress == nil {
            ipAddress = json["InternalIP"]?.string
        }

        externalIPAddress = json["ExternalIP"]?.string
        serverDevice = json["Server_Device"]?.string
        serverRelay = json["Server_Relay"]?.string
}

    var description: String {
        var desc: String = "Name: "
        if name != nil {
            desc += name!
        }

        desc += "\nSerial Number: \n"
        if serialNumber != nil {
            desc += serialNumber!
        }

        desc += "\nIP Address: \n"
        if ipAddress != nil {
            desc += ipAddress!
        }

        desc += "\nExternal IP Address: \n"
        if externalIPAddress != nil {
            desc += externalIPAddress!
        }

        desc += "\nServer Relay: \n"
        if serverRelay != nil {
            desc += serverRelay!
        }

        desc += "\nRooms: \n"
        if rooms != nil {
            for room in rooms! {
                desc += "     \(room)\n"
            }
        }

        desc += "\nDevices: \n"
        if devices != nil {
            for device in devices! {
                desc += "     \(device)\n"
            }
        }

        desc += "\nScenes: \n"
        if scenes != nil {
            for scene in scenes! {
                desc += "     \(scene)\n"
            }
        }

        return desc
    }

    func scenesForRoom(_ room: VeraRoom, excluded: [Int]? = nil) -> [VeraScene]? {
        let roomID = room.id!
        var sceneArray = [VeraScene]()
        if scenes != nil {
            for scene in scenes! {
                if excluded != nil && scene.id != nil && excluded!.contains(scene.id!) == true {
                    continue
                }

                if let sceneRoomID = scene.roomID {
                    if sceneRoomID == roomID {
                        sceneArray.append(scene)
                    }
                }
            }
        }

        if sceneArray.isEmpty == false {
            return sceneArray.sorted {$0.name < $1.name}
        }

        return nil
    }

    func devicesForRoom(_ room: VeraRoom, excluded: [Int]? = nil, categories: [VeraDevice.Category]) -> [VeraDevice]? {
        let roomID = room.id!
        var deviceArray = [VeraDevice]()
        if self.devices != nil {
            for device in self.devices! {
                if let deviceRoomID = device.roomID {
                    if excluded != nil && device.id != nil && excluded!.contains(device.id!) == true {
                        continue
                    }

                    if categories.isEmpty {
                        deviceArray.append(device)
                    } else {
                        for category in categories {
                            if deviceRoomID == roomID && device.category == category {
                                deviceArray.append(device)
                            }
                        }
                    }
                }
            }
        }

        if deviceArray.isEmpty == false {
            return deviceArray.sorted {$0.name < $1.name}
        }
        return nil
    }

    func roomsWithDevices(_ excluded: [Int]? = nil, categories: [VeraDevice.Category]) -> [VeraRoom]? {
        var roomSet = Set<VeraRoom>()
        if let rooms = self.rooms {
            for room in rooms where devicesForRoom(room, excluded: excluded, categories: categories) != nil {
                roomSet.insert(room)
            }
        }

        if roomSet.isEmpty == false {
            return roomSet.sorted {$0.name < $1.name}
        }

        return nil
    }

    func roomsWithScenes(_ excluded: [Int]? = nil) -> [VeraRoom]? {
        var roomSet = Set<VeraRoom>()
        if let rooms = self.rooms {
            for room in rooms where scenesForRoom(room, excluded: excluded) != nil {
                roomSet.insert(room)
            }
        }

        if roomSet.isEmpty == false {
            return roomSet.sorted {$0.name < $1.name}
        }

        return nil
    }

    func deviceWithIdentifier(_ identifier: Int) -> VeraDevice? {
        if let deviceArray = self.devices {
            for device in deviceArray {
                if let deviceID = device.id {
                    if deviceID == identifier {
                        return device
                    }
                }
            }
        }

        return nil
    }

    func roomWithIdentifier(_ identifier: Int) -> VeraRoom? {
        if let roomArray = self.rooms {
            for room in roomArray {
                if let roomID = room.id {
                    if roomID == identifier {
                        return room
                    }
                }
            }
        }

        return nil
    }

    func updateUnitInfo(_ unit: VeraUnit) {
        dataversion = unit.dataversion
        loadtime = unit.loadtime

        if let newDeviceArray = unit.devices {
            for newDevice in newDeviceArray {
                if let newDeviceIdentifier = newDevice.id {
                    if let device = deviceWithIdentifier(newDeviceIdentifier) {
                        device.status = newDevice.status
                        device.state = newDevice.state
                        device.comment = newDevice.comment
                        device.level = newDevice.level
                        device.temperature = newDevice.temperature
                        device.fanMode = newDevice.fanMode
                        device.heatTemperatureSetPoint = newDevice.heatTemperatureSetPoint
                        device.coolTemperatureSetPoint = newDevice.coolTemperatureSetPoint
                        device.hvacMode = newDevice.hvacMode
                        device.locked = newDevice.locked
                    }
                }
            }
        }
    }

}
