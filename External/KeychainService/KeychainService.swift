//
//  KeychainService.swift
//  Automation
//
// From http://matthewpalmer.net/blog/2014/06/21/example-ios-keychain-swift-save-query/

import UIKit
import Security

// Arguments for the keychain queries
let kSecClassValue = NSString(format: kSecClass)
let kSecAttrAccountValue = NSString(format:kSecAttrAccount)
let kSecValueDataValue = NSString(format:kSecValueData)
let kSecClassGenericPasswordValue = NSString(format:kSecClassGenericPassword)
let kSecAttrServiceValue = NSString(format:kSecAttrService)
let kSecMatchLimitValue = NSString(format:kSecMatchLimit)
let kSecReturnDataValue = NSString(format:kSecReturnData)
let kSecMatchLimitOneValue = NSString(format:kSecMatchLimitOne)

class KeychainService: NSObject {
    
    /**
    * Internal methods for querying the keychain.
    */
    
    class func save(key: NSString, data: NSString?) {
        var dataFromString: NSData?
        
        if data != nil {
            dataFromString = data!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        }
        
        var service: NSString? = NSBundle.mainBundle().bundleIdentifier
        
        if service == nil {
            return
        }
        
        // Instantiate a new default keychain query
        var keychainQuery: NSMutableDictionary = NSMutableDictionary()
        keychainQuery.setObject(kSecClassGenericPasswordValue, forKey: kSecClassValue)
        keychainQuery.setObject(service!, forKey: kSecAttrServiceValue)
        keychainQuery.setObject(key, forKey: kSecAttrAccountValue)
        
        if dataFromString != nil {
            keychainQuery.setObject(dataFromString!, forKey: kSecValueDataValue)
        }
        
        // Delete any existing items
        SecItemDelete(keychainQuery as CFDictionaryRef)
        
        // Add the new keychain item
        if dataFromString != nil {
            var status: OSStatus = SecItemAdd(keychainQuery as CFDictionaryRef, nil)
        }
    }
    
    class func load(key: NSString) -> NSString? {
        // Instantiate a new default keychain query
        // Tell the query to return a result
        // Limit our results to one item
        var service: NSString? = NSBundle.mainBundle().bundleIdentifier
        if service == nil {
            return nil
        }
        var keychainQuery: NSMutableDictionary = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service!, key, kCFBooleanTrue, kSecMatchLimitOneValue], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecReturnDataValue, kSecMatchLimitValue])
        
        var dataTypeRef :Unmanaged<AnyObject>?
        
        // Search for the keychain items
        let status: OSStatus = SecItemCopyMatching(keychainQuery, &dataTypeRef)
        
        var contentsOfKeychain: NSString?

        if status == errSecSuccess {
            let opaque = dataTypeRef?.toOpaque()
            
            
            if let op = opaque? {
                let retrievedData = Unmanaged<NSData>.fromOpaque(op).takeUnretainedValue()
                
                // Convert the data retrieved from the keychain into a string
                contentsOfKeychain = NSString(data: retrievedData, encoding: NSUTF8StringEncoding)
            } else {
                Swell.info("Nothing was retrieved from the keychain for \(key). Status code \(status)")
            }
        } else {
            Swell.info("Couldn't retrieve item from keychain: \(status)")
        }
        
        return contentsOfKeychain
    }
}