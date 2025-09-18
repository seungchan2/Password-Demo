//
//  UserDefaultsPatternStorage.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/18/25.
//

import UIKit

protocol PatternStorageProtocol {
    func savePattern(_ hashedData: Data, forKey key: String)
    func loadPattern(forKey key: String) -> Data?
    func deletePattern(forKey key: String)
    func synchronize()
}

final class UserDefaultsPatternStorage: PatternStorageProtocol {
    func savePattern(_ hashedData: Data, forKey key: String) {
        UserDefaults.standard.set(hashedData.base64EncodedString(), forKey: key)
    }
    
    func loadPattern(forKey key: String) -> Data? {
        guard let base64String = UserDefaults.standard.string(forKey: key) else { return nil }
        return Data(base64Encoded: base64String)
    }
    
    func deletePattern(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    func synchronize() {
        UserDefaults.standard.synchronize()
    }
}
 
