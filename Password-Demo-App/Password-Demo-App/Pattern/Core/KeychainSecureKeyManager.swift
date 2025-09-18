//
//  KeychainSecureKeyManager.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/18/25.
//

import UIKit

protocol SecureKeyManagerProtocol {
    func getOrCreateSalt() -> Data
    func getOrCreateDeviceKey() -> Data?
    func deleteSalt()
    func deleteDeviceKey()
}
 
final class KeychainSecureKeyManager: SecureKeyManagerProtocol {
    private let saltKey = "pattern_salt"
    private let deviceKeyTag = "device_key_tag"
    
    func getOrCreateSalt() -> Data {
        if let existingSalt = loadFromKeychain(account: saltKey) {
            return existingSalt
        }
        
        let newSalt = generateRandomData(size: 32)
        saveToKeychain(data: newSalt, account: saltKey)
        print("🧂 [Salt] 새 솔트 생성 완료")
        return newSalt
    }
    
    func getOrCreateDeviceKey() -> Data? {
        if let existingKey = loadFromKeychain(account: deviceKeyTag) {
            return existingKey
        }
        
        let newKey = generateRandomData(size: 32)
        saveToKeychain(data: newKey, account: deviceKeyTag)
        print("🔑 [DeviceKey] 새 디바이스 키 생성 완료")
        return newKey
    }
    
    func deleteSalt() {
        deleteFromKeychain(account: saltKey)
    }
    
    func deleteDeviceKey() {
        deleteFromKeychain(account: deviceKeyTag)
    }
        
    private func generateRandomData(size: Int) -> Data {
        var data = Data(count: size)
        let result = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, size, $0.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        guard result == errSecSuccess else {
            fatalError("랜덤 데이터 생성 실패")
        }
        
        return data
    }
    
    private func saveToKeychain(data: Data, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("🔑 [Keychain] 저장 실패: \(status)")
        }
    }
    
    private func loadFromKeychain(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        return status == errSecSuccess ? dataTypeRef as? Data : nil
    }
    
    private func deleteFromKeychain(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
