//
//  CipherBlockMode.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 08/03/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//

public enum CipherBlockMode {
    case ecb, cbc, pcbc, cfb, ofb, ctr

    func encryptGenerator(_ iv: Array<UInt8>?, cipherOperation: CipherOperationOnBlock, inputGenerator: AnyIterator<Array<UInt8>>) -> AnyIterator<Array<UInt8>> {
        switch (self) {
        case .cbc:
            return AnyIterator<Array<UInt8>>(CBCModeEncryptGenerator(iv: iv ?? [], cipherOperation: cipherOperation, inputGenerator: inputGenerator))
        case .cfb:
            return AnyIterator<Array<UInt8>>(CFBModeEncryptGenerator(iv: iv ?? [], cipherOperation: cipherOperation, inputGenerator: inputGenerator))
        case .ofb:
            return AnyIterator<Array<UInt8>>(OFBModeEncryptGenerator(iv: iv ?? [], cipherOperation: cipherOperation, inputGenerator: inputGenerator))
        case .ctr:
            return AnyIterator<Array<UInt8>>(CTRModeEncryptGenerator(iv: iv ?? [], cipherOperation: cipherOperation, inputGenerator: inputGenerator))
        case .pcbc:
            return AnyIterator<Array<UInt8>>(PCBCModeEncryptGenerator(iv: iv ?? [], cipherOperation: cipherOperation, inputGenerator: inputGenerator))
        case .ecb:
            return AnyIterator<Array<UInt8>>(ECBModeEncryptGenerator(iv: iv ?? [], cipherOperation: cipherOperation, inputGenerator: inputGenerator))
        }
    }

    func decryptGenerator(_ iv: Array<UInt8>?, cipherOperation: CipherOperationOnBlock, inputGenerator: AnyIterator<Array<UInt8>>) -> AnyIterator<Array<UInt8>> {
        switch (self) {
        case .cbc:
            return AnyIterator<Array<UInt8>>(CBCModeDecryptGenerator(iv: iv ?? [], cipherOperation: cipherOperation, inputGenerator: inputGenerator))
        case .cfb:
            return AnyIterator<Array<UInt8>>(CFBModeDecryptGenerator(iv: iv ?? [], cipherOperation: cipherOperation, inputGenerator: inputGenerator))
        case .ofb:
            return AnyIterator<Array<UInt8>>(OFBModeDecryptGenerator(iv: iv ?? [], cipherOperation: cipherOperation, inputGenerator: inputGenerator))
        case .ctr:
            return AnyIterator<Array<UInt8>>(CTRModeDecryptGenerator(iv: iv ?? [], cipherOperation: cipherOperation, inputGenerator: inputGenerator))
        case .pcbc:
            return AnyIterator<Array<UInt8>>(PCBCModeDecryptGenerator(iv: iv ?? [], cipherOperation: cipherOperation, inputGenerator: inputGenerator))
        case .ecb:
            return AnyIterator<Array<UInt8>>(ECBModeDecryptGenerator(iv: iv ?? [], cipherOperation: cipherOperation, inputGenerator: inputGenerator))
        }
    }

    var options: BlockModeOptions {
        switch (self) {
        case .cbc:
            return [.InitializationVectorRequired, .PaddingRequired]
        case .cfb:
            return .InitializationVectorRequired
        case .ctr:
            return .InitializationVectorRequired
        case .ecb:
            return .PaddingRequired
        case .ofb:
            return .InitializationVectorRequired
        case .pcbc:
            return [.InitializationVectorRequired, .PaddingRequired]
        }
    }

    /**
     Process input blocks with given block cipher mode. With fallback to plain mode.

     - parameter blocks: cipher block size blocks
     - parameter iv:     IV
     - parameter cipher: single block encryption closure

     - returns: encrypted bytes
     */
//    func encryptBlocks(blocks:[[UInt8]], iv:[UInt8]?, cipherOperation:CipherOperationOnBlock) throws -> [UInt8] {
//
//        // if IV is not available, fallback to plain
//        var finalBlockMode:CipherBlockMode = self
//        if (iv == nil) {
//            finalBlockMode = .ECB
//        }
//
//        return try finalBlockMode.mode.encryptBlocks(blocks, iv: iv, cipherOperation: cipherOperation)
//    }
//
//    func decryptBlocks(blocks:[[UInt8]], iv:[UInt8]?, cipherOperation:CipherOperationOnBlock) throws -> [UInt8] {
//        // if IV is not available, fallback to plain
//        var finalBlockMode:CipherBlockMode = self
//        if (iv == nil) {
//            finalBlockMode = .ECB
//        }
//
//        return try finalBlockMode.mode.decryptBlocks(blocks, iv: iv, cipherOperation: cipherOperation)
//    }
}
