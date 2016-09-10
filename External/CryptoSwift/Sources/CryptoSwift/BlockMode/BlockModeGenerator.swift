//
//  BlockModeGenerator.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 08/03/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//

// I have no better name for that

enum BlockError: Error {
    case missingInitializationVector
}

typealias CipherOperationOnBlock = (_ block: [UInt8]) -> [UInt8]?

protocol BlockModeGenerator: IteratorProtocol {
    var options: BlockModeOptions { get }
    init(iv: Array<UInt8>, cipherOperation: CipherOperationOnBlock, inputGenerator: AnyIterator<Element>)
}
