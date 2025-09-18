//
//  UIMode.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/18/25.
//

import UIKit

enum UIMode {
    case registration
    case verification
    case locked
    
    var title: String {
        switch self {
        case .registration: return "패턴 등록"
        case .verification: return "패턴 인증"
        case .locked: return "계정 잠금"
        }
    }
    
    var subtitle: String {
        switch self {
        case .registration: return "보안 패턴을 설정해주세요"
        case .verification: return "저장된 패턴을 입력해주세요"
        case .locked: return "시도 횟수를 초과했습니다"
        }
    }
    
    var color: UIColor {
        switch self {
        case .registration:
            return .systemBlue
        case .verification:
            return .systemYellow
        case .locked:
            return .systemRed
        }
    }
}
