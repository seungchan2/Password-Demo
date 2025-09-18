//
//  HybridCryptography.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/18/25.
//

import UIKit

import CryptoKit
import CommonCrypto
import Security

protocol CryptographyProtocol {
    func encrypt(_ data: Data, with key: Data) -> Data?
    func decrypt(_ encryptedData: Data, with key: Data) -> Data?
    func hash(_ data: Data, salt: Data) -> Data
}

final class HybridCryptography: CryptographyProtocol {
    func encrypt(_ data: Data, with key: Data) -> Data? {
        if #available(iOS 13.0, *) {
            return encryptWithCryptoKit(data, key: key)
        } else {
            return encryptWithCommonCrypto(data, key: key)
        }
    }
    
    func decrypt(_ encryptedData: Data, with key: Data) -> Data? {
        if #available(iOS 13.0, *) {
            return decryptWithCryptoKit(encryptedData, key: key)
        } else {
            return decryptWithCommonCrypto(encryptedData, key: key)
        }
    }
    
    func hash(_ data: Data, salt: Data) -> Data {
        if #available(iOS 13.0, *) {
            var hasher = SHA256()
            hasher.update(data: salt)
            hasher.update(data: data)
            return Data(hasher.finalize())
        } else {
            return hashWithCommonCrypto(data, salt: salt)
        }
    }
    
    @available(iOS 13.0, *)
    private func encryptWithCryptoKit(_ data: Data, key: Data) -> Data? {
        do {
            let symmetricKey = SymmetricKey(data: key)
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
            
            var result = Data()
            result.append(sealedBox.nonce.withUnsafeBytes { Data($0) })
            result.append(sealedBox.ciphertext)
            result.append(sealedBox.tag)
            
            return result
        } catch {
            print("🔐 [Encrypt] CryptoKit 실패: \(error)")
            return nil
        }
    }
    
    @available(iOS 13.0, *)
    private func decryptWithCryptoKit(_ encryptedData: Data, key: Data) -> Data? {
        guard encryptedData.count > 28 else { return nil }
        
        do {
            let symmetricKey = SymmetricKey(data: key)
            let nonce = encryptedData.prefix(12)
            let tag = encryptedData.suffix(16)
            let ciphertext = encryptedData.dropFirst(12).dropLast(16)
            
            let sealedBox = try AES.GCM.SealedBox(
                nonce: AES.GCM.Nonce(data: nonce),
                ciphertext: ciphertext,
                tag: tag
            )
            
            return try AES.GCM.open(sealedBox, using: symmetricKey)
        } catch {
            print("🔐 [Decrypt] CryptoKit 실패: \(error)")
            return nil
        }
    }
        
    private func encryptWithCommonCrypto(_ data: Data, key: Data) -> Data? {
        var iv = Data(count: kCCBlockSizeAES128)
        let ivResult = iv.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, $0.bindMemory(to: UInt8.self).baseAddress!)
        }
        guard ivResult == errSecSuccess else { return nil }
        
        let bufferSize = data.count + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesEncrypted: size_t = 0
        
        let status = key.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                data.withUnsafeBytes { dataBytes in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.bindMemory(to: UInt8.self).baseAddress,
                        key.count,
                        ivBytes.bindMemory(to: UInt8.self).baseAddress,
                        dataBytes.bindMemory(to: UInt8.self).baseAddress,
                        data.count,
                        &buffer,
                        bufferSize,
                        &numBytesEncrypted
                    )
                }
            }
        }
        
        guard status == kCCSuccess else { return nil }
        
        var result = Data()
        result.append(iv)
        result.append(Data(buffer.prefix(numBytesEncrypted)))
        return result
    }
    
    private func decryptWithCommonCrypto(_ encryptedData: Data, key: Data) -> Data? {
        guard encryptedData.count > kCCBlockSizeAES128 else { return nil }
        
        let iv = encryptedData.prefix(kCCBlockSizeAES128)
        let ciphertext = encryptedData.dropFirst(kCCBlockSizeAES128)
        
        let bufferSize = ciphertext.count + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesDecrypted: size_t = 0
        
        let status = key.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                ciphertext.withUnsafeBytes { cipherBytes in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.bindMemory(to: UInt8.self).baseAddress,
                        key.count,
                        ivBytes.bindMemory(to: UInt8.self).baseAddress,
                        cipherBytes.bindMemory(to: UInt8.self).baseAddress,
                        ciphertext.count,
                        &buffer,
                        bufferSize,
                        &numBytesDecrypted
                    )
                }
            }
        }
        
        guard status == kCCSuccess else { return nil }
        return Data(buffer.prefix(numBytesDecrypted))
    }
    
    private func hashWithCommonCrypto(_ data: Data, salt: Data) -> Data {
        var context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)
        
        salt.withUnsafeBytes { saltBytes in
            CC_SHA256_Update(&context, saltBytes.bindMemory(to: UInt8.self).baseAddress, CC_LONG(salt.count))
        }
        
        data.withUnsafeBytes { dataBytes in
            CC_SHA256_Update(&context, dataBytes.bindMemory(to: UInt8.self).baseAddress, CC_LONG(data.count))
        }
        
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256_Final(&digest, &context)
        
        return Data(digest)
    }
}
