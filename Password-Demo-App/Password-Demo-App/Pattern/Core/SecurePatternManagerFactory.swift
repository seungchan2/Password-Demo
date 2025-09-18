//
//  SecurePatternManagerFactory.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/18/25.
//

import UIKit

final class SecurePatternManagerFactory {
    
    static func createDefault() -> SecurePatternManagerProtocol {
        let storage = UserDefaultsPatternStorage()
        let keyManager = KeychainSecureKeyManager()
        let cryptography = HybridCryptography()
        let deviceInfoProvider = UIDeviceInfoProvider()
        let obfuscator = DeviceBasedPatternObfuscator(deviceInfoProvider: deviceInfoProvider)
        let attemptManager = UserDefaultsAttemptManager()
        
        return ModularSecurePatternManager(
            storage: storage,
            keyManager: keyManager,
            cryptography: cryptography,
            obfuscator: obfuscator,
            attemptManager: attemptManager
        )
    }
}
