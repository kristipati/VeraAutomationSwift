//
//  MAC.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 03/09/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

/**
*  Message Authentication
*/
public enum Authenticator {
    
    public enum Error: Error {
        case authenticateError
    }
    
    /**
    Poly1305
    
    - parameter key: 256-bit key
    */
    case poly1305(key: [UInt8])
    case hmac(key: [UInt8], variant:CryptoSwift.HMAC.Variant)
    
    /**
    Generates an authenticator for message using a one-time key and returns the 16-byte result
    
    - returns: 16-byte message authentication code
    */
    public func authenticate(_ message: [UInt8]) throws -> [UInt8] {
        switch (self) {
        case .poly1305(let key):
            guard let auth = CryptoSwift.Poly1305.authenticate(key: key, message: message) else {
                throw Error.authenticateError
            }
            return auth
        case .hmac(let key, let variant):
            guard let auth = CryptoSwift.HMAC.authenticate(key: key, message: message, variant: variant) else {
                throw Error.authenticateError
            }
            return auth
        }
    }
}
