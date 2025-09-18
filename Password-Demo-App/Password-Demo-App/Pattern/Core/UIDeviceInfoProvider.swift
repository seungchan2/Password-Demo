//
//  UIDeviceInfoProvider.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/18/25.
//

import UIKit

protocol DeviceInfoProviderProtocol {
    func getDeviceIdentifier() -> String
}

final class UIDeviceInfoProvider: DeviceInfoProviderProtocol {
    func getDeviceIdentifier() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "DEFAULT_DEVICE_ID"
    }
}
