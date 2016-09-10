//
//  CFB.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 08/03/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//
//  Cipher feedback (CFB)
//

struct CFBModeEncryptGenerator: BlockModeGenerator {
    typealias Element = Array<UInt8>
    let options: BlockModeOptions = [.InitializationVectorRequired, .PaddingRequired]

    fileprivate let iv: Element
    fileprivate let inputGenerator: AnyIterator<Element>

    fileprivate let cipherOperation: CipherOperationOnBlock
    fileprivate var prevCiphertext: Element?

    init(iv: Array<UInt8>, cipherOperation: @escaping CipherOperationOnBlock, inputGenerator: AnyIterator<Array<UInt8>>) {
        self.iv = iv
        self.cipherOperation = cipherOperation
        self.inputGenerator = inputGenerator
    }

    mutating func next() -> Element? {
        guard let plaintext = inputGenerator.next(),
            let ciphertext = cipherOperation(prevCiphertext ?? iv)
            else {
                return nil
        }

        self.prevCiphertext = xor(plaintext, ciphertext)
        return self.prevCiphertext
    }
}

struct CFBModeDecryptGenerator: BlockModeGenerator {
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
            let decrypted = cipherOperation(self.prevCiphertext ?? iv)
            else {
                return nil
        }

        let result = xor(decrypted, ciphertext)
        self.prevCiphertext = ciphertext
        return result
    }
}
