//
//  DecodingExtensions.swift
//  Automation
//
//  Created by Scott Gruby on 9/16/17.
//  Copyright © 2017 Gruby Solutions. All rights reserved.
//

import Foundation

extension KeyedDecodingContainer {
    func decodeAsInteger(key: KeyedDecodingContainer.Key) -> Int? {
        if let int = try? decode(Int.self, forKey: key) {
            return int
        } else if let str = try? decode(String.self, forKey: key) {
            return Int(str)
        }
        return nil
    }

    func decodeAsDouble(key: KeyedDecodingContainer.Key) -> Double? {
        if let double = try? decode(Double.self, forKey: key) {
            return double
        } else if let str = try? decode(String.self, forKey: key) {
            return Double(str)
        }
        return nil
    }

    func decodeAsBoolean(key: KeyedDecodingContainer.Key) -> Bool? {
        if let bool = try? decode(Bool.self, forKey: key) {
            return bool
        } else if let int = try? decode(Int.self, forKey: key) {
            return int == 1
        } else if let str = try? decode(String.self, forKey: key) {
            return Int(str) == 1
        }
        return nil
    }
}
