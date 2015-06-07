
//
//  Unit.swift
//  Automation
//
//  Created by Scott Gruby on 10/5/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import Foundation

public class Unit : Deserializable, Printable {

    public var serialNumber:String?
    var firmwareVersion:String?
    var name:String?
    public var ipAddress:String?
    var users:[String]?
    var activeServer:String?
    var forwardServers:[ForwardServer]?
    var loadtime = 0
    var dataversion = 0
    public var fullload:Bool?
    public var rooms:[Room]?
    public var devices:[Device]?
    public var scenes:[Scene]?
    public var serverDevice:String?
    public var serverRelay:String?
    
    public required init(data: [String: AnyObject]) {
        serialNumber <-- data["serialNumber"]
        firmwareVersion <-- data["FirmwareVersion"]
        name <-- data["name"]
        ipAddress <-- data["ipAddress"]
        users <-- data["users"]
        activeServer <-- data["active_server"]
        forwardServers <-- data["forwardServers"]
        rooms <-- data["rooms"]
        fullload <-- data["full"]
        devices <-- data["devices"]
        scenes <-- data["scenes"]
        loadtime <-- data["loadtime"]
        dataversion <-- data["dataversion"]
        
        if serialNumber == nil {
            serialNumber <-- data["PK_Device"]
        }
        
        if ipAddress == nil {
            ipAddress <-- data["InternalIP"]
        }
        
        serverDevice <-- data["Server_Device"]
        serverRelay <-- data["Server_Relay"]
    }

    public var description: String {
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
    
    func scenesForRoom(room: Room, excluded:[Int]? = nil)->[Scene]? {
        let roomID = room.id!
        var sceneArray = [Scene]()
        if scenes != nil {
            for scene in scenes! {
                if excluded != nil && scene.id != nil && contains(excluded!, scene.id!) == true {
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
            return sceneArray.sorted({$0.name<$1.name})
        }

        return nil
    }

    func devicesForRoom(room: Room, excluded:[Int]? = nil, categories: [Device.Category])->[Device]? {
        let roomID = room.id!
        var deviceArray = [Device]()
        if self.devices != nil {
            for device in self.devices! {
                if let deviceRoomID = device.roomID {
                    if excluded != nil && device.id != nil && contains(excluded!, device.id!) == true {
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
            return deviceArray.sorted({$0.name<$1.name})
        }
        return nil
    }

    func roomsWithDevices(excluded:[Int]? = nil, categories: [Device.Category])->[Room]? {
        var roomSet = Set<Room>()
        if let rooms = self.rooms {
            for room in rooms {
                if let deviceArray = self.devicesForRoom(room, excluded: excluded, categories: categories) {
                    roomSet.append(room)
                }
            }
        }
        
        if roomSet.isEmpty == false {
            return roomSet.elements.sorted({$0.name<$1.name})
        }
        
        return nil
    }

    func roomsWithScenes(excluded:[Int]? = nil)->[Room]? {
        var roomSet = Set<Room>()
        if let rooms = self.rooms {
            for room in rooms {
                if let deviceArray = scenesForRoom(room, excluded: excluded) {
                    roomSet.append(room)
                }
            }
        }
        
        if roomSet.isEmpty == false {
            return roomSet.elements.sorted({$0.name<$1.name})
        }
        
        return nil
    }

    func deviceWithIdentifier(identifier: Int)->Device? {
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

    func roomWithIdentifier(identifier: Int)->Room? {
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

    func updateUnitInfo(unit: Unit) {
        dataversion = unit.dataversion
        loadtime = unit.loadtime
        
        if let newDeviceArray = unit.devices {
            for newDevice in newDeviceArray {
                if let newDeviceIdentifier = newDevice.id {
                    if let device = deviceWithIdentifier(newDeviceIdentifier) {
                        device.status = newDevice.status;
                        device.state = newDevice.state;
                        device.comment = newDevice.comment;
                        device.level = newDevice.level;
                        device.temperature = newDevice.temperature;
                        device.fanMode = newDevice.fanMode;
                        device.heatTemperatureSetPoint = newDevice.heatTemperatureSetPoint;
                        device.coolTemperatureSetPoint = newDevice.coolTemperatureSetPoint;
                        device.hvacMode = newDevice.hvacMode;
                        device.locked = newDevice.locked;
                    }
                }
            }
        }
    }

}
