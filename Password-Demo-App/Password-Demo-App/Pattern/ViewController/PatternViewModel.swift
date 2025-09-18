//
//  PatternViewModel.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/18/25.
//

//
//  ViewModelType.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/18/25.
//

import UIKit

import SnapKit
import RxSwift
import RxCocoa

final class PatternViewModel: ViewModelType {
        
    struct Input {
        let viewDidLoad: Observable<Void>
        let patternCompleted: Observable<[Int]>
        let deletePatternTapped: Observable<Void>
        let showSecurityInfoTapped: Observable<Void>
        let backButtonTapped: Observable<Void>
        let timerTick: Observable<Void>
    }
    
    struct Output {
        let uiMode: Driver<UIMode>
        let statusText: Driver<String>
        let statusColor: Driver<UIColor>
        let securityInfoText: Driver<String>
        let showAlert: Driver<AlertModel>
        let dismissViewController: Driver<Void>
        let isPatternInteractionEnabled: Driver<Bool>
        let isDeleteButtonHidden: Driver<Bool>
        let shouldResetPattern: Driver<Void>
    }
        
    private let patternManager: SecurePatternManagerProtocol
    private let disposeBag = DisposeBag()
        
    private let uiModeRelay = BehaviorRelay<UIMode>(value: .registration)
    private let alertRelay = PublishRelay<AlertModel>()
    private let dismissRelay = PublishRelay<Void>()
    private let resetPatternRelay = PublishRelay<Void>()
    
    
    init(patternManager: SecurePatternManagerProtocol = SecurePatternManagerFactory.createDefault()) {
        self.patternManager = patternManager
    }
        
    func transform(input: Input) -> Output {
        
        input.viewDidLoad
            .subscribe(with: self) { owner, _ in
                owner.checkInitialSecurityStatus()
            }
            .disposed(by: self.disposeBag)
        
        input.patternCompleted
            .subscribe(with: self) { owner, pattern in
                owner.handlePatternCompleted(pattern)
            }
            .disposed(by: self.disposeBag)
        
        input.deletePatternTapped
            .subscribe(with: self) { owner, _ in
                owner.deletePattern()
            }
            .disposed(by: disposeBag)
        
        input.showSecurityInfoTapped
            .subscribe(with: self) { owner, _ in
                owner.showSecurityInfo()
            }
            .disposed(by: self.disposeBag)
        
        input.backButtonTapped
            .subscribe(with: self) { owner, _ in
                owner.dismissRelay.accept(())
            }
            .disposed(by: self.disposeBag)
        
        input.timerTick
            .subscribe(with: self) { owner, _ in
                owner.updateSecurityStatus()
            }
            .disposed(by: self.disposeBag)
        
        let statusText = uiModeRelay.asDriver()
            .map { [weak self] mode -> String in
                return self?.updateStatusText(for: mode) ?? ""
            }
        
        let statusColor = uiModeRelay.asDriver()
            .map { [weak self] mode -> UIColor in
                return self?.updateStatusColor(for: mode) ?? .systemYellow
            }
        
        let securityInfoText = uiModeRelay.asDriver()
            .map { [weak self] _ -> String in
                return self?.updateSecurityInfoText() ?? ""
            }
        
        let isPatternInteractionEnabled = uiModeRelay.asDriver()
            .map { mode in
                return mode != .locked
            }
        
        let isDeleteButtonHidden = uiModeRelay.asDriver()
            .map { mode in
                return mode != .verification
            }
        
        return Output(
            uiMode: uiModeRelay.asDriver(),
            statusText: statusText,
            statusColor: statusColor,
            securityInfoText: securityInfoText,
            showAlert: alertRelay.asDriver(onErrorJustReturn: AlertModel.defaultAlert),
            dismissViewController: dismissRelay.asDriver(onErrorJustReturn: ()),
            isPatternInteractionEnabled: isPatternInteractionEnabled,
            isDeleteButtonHidden: isDeleteButtonHidden,
            shouldResetPattern: resetPatternRelay.asDriver(onErrorJustReturn: ())
        )
    }
        
    private func checkInitialSecurityStatus() {
        let securityInfo = patternManager.getSecurityInfo()
        let isLocked = securityInfo["계정 잠김"] as? Bool ?? false
        let isPatternSet = patternManager.isPatternSet()
        
        if isLocked {
            uiModeRelay.accept(.locked)
        } else if isPatternSet {
            uiModeRelay.accept(.verification)
        } else {
            uiModeRelay.accept(.registration)
        }
    }
    
    private func updateSecurityStatus() {
        let securityInfo = patternManager.getSecurityInfo()
        let isLocked = securityInfo["계정 잠김"] as? Bool ?? false
        let currentMode = uiModeRelay.value
        
        if isLocked && currentMode != .locked {
            uiModeRelay.accept(.locked)
        } else if !isLocked && currentMode == .locked {
            uiModeRelay.accept(.verification)
        }
    }
    
    private func handlePatternCompleted(_ pattern: [Int]) {
        let securityInfo = patternManager.getSecurityInfo()
        let isLocked = securityInfo["계정 잠김"] as? Bool ?? false
        
        guard !isLocked else { return }
        
        if patternManager.isPatternSet() {
            verifyPattern(pattern)
        } else {
            handlePatternRegistration(pattern)
        }
    }
    
    private func handlePatternRegistration(_ pattern: [Int]) {
        guard pattern.count >= 4 else {
            alertRelay.accept(AlertModel(
                title: "패턴 오류",
                message: "최소 4개 이상의 점을 연결해주세요.",
                completion: { [weak self] in
                    self?.resetPatternRelay.accept(())
                }
            ))
            return
        }
        
        patternManager.savePattern(pattern)
        
        alertRelay.accept(AlertModel(
            title: "패턴 저장 완료",
            message: "새 패턴이 안전하게 저장되었습니다.",
            completion: { [weak self] in
                self?.uiModeRelay.accept(.verification)
                self?.resetPatternRelay.accept(())
            }
        ))
    }
    
    private func verifyPattern(_ pattern: [Int]) {
        if patternManager.verifyPattern(pattern) {
            alertRelay.accept(AlertModel(
                title: "인증 성공",
                message: "패턴이 일치합니다!",
                completion: { [weak self] in
                    self?.resetPatternRelay.accept(())
                }
            ))
        } else {
            let securityInfo = patternManager.getSecurityInfo()
            let attemptCount = securityInfo["실패 횟수"] as? Int ?? 0
            let maxAttempts = securityInfo["최대 시도 횟수"] as? Int ?? 5
            let isLocked = securityInfo["계정 잠김"] as? Bool ?? false
            let remaining = maxAttempts - attemptCount
            
            if isLocked {
                uiModeRelay.accept(.locked)
                let lockoutTime = securityInfo["남은 잠금 시간(초)"] as? Int ?? 0
                alertRelay.accept(AlertModel(
                    title: "계정 잠금",
                    message: "최대 시도 횟수를 초과했습니다. \(lockoutTime)초 후 다시 시도해주세요.",
                    completion: { [weak self] in
                        self?.resetPatternRelay.accept(())
                    }
                ))
            } else {
                alertRelay.accept(AlertModel(
                    title: "인증 실패",
                    message: "패턴이 일치하지 않습니다.\n남은 시도 횟수: \(remaining)회",
                    completion: { [weak self] in
                        self?.resetPatternRelay.accept(())
                    }
                ))
            }
        }
    }
    
    private func deletePattern() {
        alertRelay.accept(AlertModel(
            title: "패턴 삭제",
            message: "저장된 패턴과 모든 보안 데이터를 삭제하시겠습니까?",
            style: .actionSheet,
            actions: [
                AlertAction(title: "취소", style: .cancel),
                AlertAction(title: "삭제", style: .destructive) { [weak self] in
                    self?.patternManager.deletePattern()
                    self?.uiModeRelay.accept(.registration)
                    print("🗑️ [ViewModel] 패턴 삭제 완료")
                }
            ]
        ))
    }
    
    private func showSecurityInfo() {
        let securityInfo = patternManager.getSecurityInfo()
        var message = ""
        for (key, value) in securityInfo {
            message += "\(key): \(value)\n"
        }
        
        alertRelay.accept(AlertModel(
            title: "보안 상태 정보",
            message: message
        ))
    }
    
    private func updateStatusText(for mode: UIMode) -> String {
        switch mode {
        case .registration:
            return "새 패턴을 설정하세요 (최소 4개 점)"
        case .verification:
            return "패턴을 입력하여 인증하세요"
        case .locked:
            let securityInfo = patternManager.getSecurityInfo()
            let remainingTime = securityInfo["남은 잠금 시간(초)"] as? Int ?? 0
            return "잠금 해제까지 \(remainingTime)초 남음"
        }
    }
    
    private func updateStatusColor(for mode: UIMode) -> UIColor {
        return mode.color
    }
    
    private func updateSecurityInfoText() -> String {
        let info = patternManager.getSecurityInfo()
        let attemptCount = info["실패 횟수"] as? Int ?? 0
        let isLocked = info["계정 잠김"] as? Bool ?? false
        let hasPattern = info["패턴 설정됨"] as? Bool ?? false
        let maxAttempts = info["최대 시도 횟수"] as? Int ?? 5
        
        var infoText = ""
        if hasPattern {
            infoText += "패턴 설정됨 | "
        }
        if isLocked {
            infoText += "계정 잠금 상태 | "
        }
        infoText += "실패: \(attemptCount)/\(maxAttempts)"
        
        return infoText
    }
}



