//
//  SecurePatternManager.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/16/25.
//

import UIKit

import CryptoKit
import CommonCrypto
import Security

protocol SecurePatternManagerProtocol {
    func savePattern(_ pattern: [Int])
    func verifyPattern(_ pattern: [Int]) -> Bool
    func isPatternSet() -> Bool
    func deletePattern()
    func getSecurityInfo() -> [String: Any]
}

final class ModularSecurePatternManager: SecurePatternManagerProtocol {
    
    private let storage: PatternStorageProtocol
    private let keyManager: SecureKeyManagerProtocol
    private let cryptography: CryptographyProtocol
    private let obfuscator: PatternObfuscatorProtocol
    private let attemptManager: AttemptManagerProtocol
    
    private let hashedPatternKey = "hashed_pattern_secure"
    
    init(
        storage: PatternStorageProtocol,
        keyManager: SecureKeyManagerProtocol,
        cryptography: CryptographyProtocol,
        obfuscator: PatternObfuscatorProtocol,
        attemptManager: AttemptManagerProtocol
    ) {
        self.storage = storage
        self.keyManager = keyManager
        self.cryptography = cryptography
        self.obfuscator = obfuscator
        self.attemptManager = attemptManager
    }
    
    func savePattern(_ pattern: [Int]) {
        /// 1. 솔트 생성/가져오기
        let salt = keyManager.getOrCreateSalt()
        
        /// 2. 패턴 난독화
        let obfuscatedPattern = obfuscator.obfuscate(pattern)
        
        /// 3. 해시 생성
        guard let patternData = obfuscatedPattern.data(using: .utf8) else {
            return
        }
        let hashedPattern = cryptography.hash(patternData, salt: salt)
        
        /// 4. 디바이스 키로 암호화
        guard let deviceKey = keyManager.getOrCreateDeviceKey(),
              let encryptedHash = cryptography.encrypt(hashedPattern, with: deviceKey) else {
            return
        }
        
        /// 5. 저장
        storage.savePattern(encryptedHash, forKey: hashedPatternKey)
        storage.synchronize()
        
        /// 6. 시도 횟수 초기화
        attemptManager.resetAttemptCount()
    }
    
    func verifyPattern(_ pattern: [Int]) -> Bool {
        /// 1. 잠금 상태 확인
        if attemptManager.isLockedOut() {
            return false
        }
        
        /// 2. 저장된 해시 복호화
        guard let encryptedHash = storage.loadPattern(forKey: hashedPatternKey),
              let deviceKey = keyManager.getOrCreateDeviceKey(),
              let storedHash = cryptography.decrypt(encryptedHash, with: deviceKey) else {
            return false
        }
        
        /// 3. 입력 패턴 해시 생성
        let salt = keyManager.getOrCreateSalt()
        let obfuscatedPattern = obfuscator.obfuscate(pattern)
        guard let patternData = obfuscatedPattern.data(using: .utf8) else {
            return false
        }
        let inputHash = cryptography.hash(patternData, salt: salt)
                
        /// 4. 해시 비교 (상수 시간 비교)
        let isMatch = constantTimeCompare(storedHash, inputHash)
        
        if isMatch {
            attemptManager.resetAttemptCount()
            return true
        } else {
            attemptManager.incrementAttemptCount()
            return false
        }
    }
    
    func isPatternSet() -> Bool {
        return storage.loadPattern(forKey: hashedPatternKey) != nil
    }
    
    func deletePattern() {
        storage.deletePattern(forKey: hashedPatternKey)
        storage.synchronize()
        attemptManager.resetAttemptCount()
        keyManager.deleteSalt()
        keyManager.deleteDeviceKey()
    }
    
    func getSecurityInfo() -> [String: Any] {
        return [
            "패턴 설정됨": isPatternSet(),
            "계정 잠김": attemptManager.isLockedOut(),
            "실패 횟수": attemptManager.getAttemptCount(),
            "최대 시도 횟수": attemptManager.maxAttempts,
            "남은 잠금 시간(초)": Int(attemptManager.getRemainingLockoutTime())
        ]
    }
        
    private func constantTimeCompare(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else { return false }
        
        var result: UInt8 = 0
        for i in 0..<a.count {
            result |= a[i] ^ b[i]
        }
        return result == 0
    }
}
