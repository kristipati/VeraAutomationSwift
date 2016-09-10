//
//  CBC.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 08/03/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//
//  Cipher-block chaining (CBC)
//

struct CBCModeEncryptGenerator: BlockModeGenerator {
    typealias Element = Array<UInt8>
    let options: BlockModeOptions = [.InitializationVectorRequired, .PaddingRequired]

    fileprivate let iv: Element
    fileprivate let inputGenerator: AnyIterator<Element>

    fileprivate let cipherOperation: CipherOperationOnBlock
    fileprivate var prevCiphertext: Element?

    init(iv: Array<UInt8>, cipherOperation: @escaping CipherOperationOnBlock, inputGenerator: AnyIterator<Element>) {
        self.iv = iv
        self.cipherOperation = cipherOperation
        self.inputGenerator = inputGenerator
    }

    mutating func next() -> Element? {
        guard let plaintext = inputGenerator.next(),
              let encrypted = cipherOperation(xor(prevCiphertext ?? iv, plaintext))
        else {
            return nil
        }

        self.prevCiphertext = encrypted
        return encrypted
    }
}

struct CBCModeDecryptGenerator: BlockModeGenerator {
    typealias Element = Array<UInt8>
    let options: BlockModeOptions = [.InitializationVectorRequired, .PaddingRequired]

    fileprivate let iv: Element
    fileprivate let inputGenerator: AnyIterator<Element>

    fileprivate let cipherOperation: CipherOperationOnBlock
    fileprivate var prevCiphertext: Element?

    init(iv: Array<UInt8>, cipherOperation: @escaping CipherOperationOnBlock, inputGenerator: AnyIterator<Element>) {
        self.iv = iv
        self.cipherOperation = cipherOperation
        self.inputGenerator = inputGenerator
    }

    mutating func next() -> Element? {
        guard let ciphertext = inputGenerator.next(),
              let decrypted = cipherOperation(ciphertext)
        else {
            return nil
        }

        let result = xor(prevCiphertext ?? iv, decrypted)
        self.prevCiphertext = ciphertext
        return result
    }
}
