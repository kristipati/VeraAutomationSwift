//
//  CipherBlockMode.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 27/12/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//
//  Electronic codebook (ECB)
//

struct ECBModeEncryptGenerator: BlockModeGenerator {
    typealias Element = Array<UInt8>
    let options: BlockModeOptions = [.InitializationVectorRequired, .PaddingRequired]

    fileprivate let iv: Element
    fileprivate let inputGenerator: AnyIterator<Element>

    fileprivate let cipherOperation: CipherOperationOnBlock

    init(iv: Array<UInt8>, cipherOperation: @escaping CipherOperationOnBlock, inputGenerator: AnyIterator<Array<UInt8>>) {
        self.iv = iv
        self.cipherOperation = cipherOperation
        self.inputGenerator = inputGenerator
    }

    mutating func next() -> Element? {
        guard let plaintext = inputGenerator.next(),
              let encrypted = cipherOperation(plaintext)
        else {
            return nil
        }

        return encrypted
    }
}

typealias ECBModeDecryptGenerator = ECBModeEncryptGenerator
