//
//  UserDefaultsAttemptManager.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/18/25.
//

import UIKit

protocol AttemptManagerProtocol {
    var maxAttempts: Int { get }
    var lockoutDuration: TimeInterval { get }
    func incrementAttemptCount()
    func resetAttemptCount()
    func getAttemptCount() -> Int
    func isLockedOut() -> Bool
    func getRemainingLockoutTime() -> TimeInterval
}

final class UserDefaultsAttemptManager: AttemptManagerProtocol {
    let maxAttempts: Int = 3
    let lockoutDuration: TimeInterval = 300
    
    private let attemptCountKey = "attempt_count"
    private let lastAttemptKey = "last_attempt_time"
    private let isLockedKey = "is_locked"
    
    func incrementAttemptCount() {
        let currentCount = UserDefaults.standard.integer(forKey: attemptCountKey)
        let newCount = currentCount + 1
        
        UserDefaults.standard.set(newCount, forKey: attemptCountKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastAttemptKey)
        
        if newCount >= maxAttempts {
            UserDefaults.standard.set(true, forKey: isLockedKey)
            print("🔒 [Security] 계정 잠금 - 시도 횟수 초과 (\(newCount)/\(maxAttempts))")
        }
        
        UserDefaults.standard.synchronize()
    }
    
    func resetAttemptCount() {
        UserDefaults.standard.removeObject(forKey: attemptCountKey)
        UserDefaults.standard.removeObject(forKey: lastAttemptKey)
        UserDefaults.standard.removeObject(forKey: isLockedKey)
        UserDefaults.standard.synchronize()
    }
    
    func getAttemptCount() -> Int {
        return UserDefaults.standard.integer(forKey: attemptCountKey)
    }
    
    func isLockedOut() -> Bool {
        guard UserDefaults.standard.bool(forKey: isLockedKey) else {
            return false
        }
        
        let lastAttemptTime = UserDefaults.standard.double(forKey: lastAttemptKey)
        let currentTime = Date().timeIntervalSince1970
        
        if currentTime - lastAttemptTime > lockoutDuration {
            resetAttemptCount()
            return false
        }
        
        return true
    }
    
    func getRemainingLockoutTime() -> TimeInterval {
        guard isLockedOut() else { return 0 }
        
        let lastAttemptTime = UserDefaults.standard.double(forKey: lastAttemptKey)
        let currentTime = Date().timeIntervalSince1970
        let elapsed = currentTime - lastAttemptTime
        
        return max(0, lockoutDuration - elapsed)
    }
}
