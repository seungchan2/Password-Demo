//
//  DeviceBasedPatternObfuscator.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/18/25.
//

import UIKit

protocol PatternObfuscatorProtocol {
    func obfuscate(_ pattern: [Int]) -> String
}

final class DeviceBasedPatternObfuscator: PatternObfuscatorProtocol {
    private let deviceInfoProvider: DeviceInfoProviderProtocol
    
    init(deviceInfoProvider: DeviceInfoProviderProtocol) {
        self.deviceInfoProvider = deviceInfoProvider
    }
    
    func obfuscate(_ pattern: [Int]) -> String {
        var obfuscated = ""
        let deviceId = deviceInfoProvider.getDeviceIdentifier()
        
        for (index, point) in pattern.enumerated() {
            let hexValue = String(format: "%02X", point)
            let positionHash = String(format: "%02X", (point * index + 17) % 256)
            let deviceFragment = String(deviceId.suffix(2))
            
            obfuscated += "\(hexValue)\(positionHash)\(deviceFragment)"
            
            if index < pattern.count - 1 {
                obfuscated += "|"
            }
        }
        
        let checksum = pattern.reduce(0, +) * pattern.count + deviceId.count
        obfuscated += "|\(String(format: "%08X", checksum))"
        
        return obfuscated
    }
}
