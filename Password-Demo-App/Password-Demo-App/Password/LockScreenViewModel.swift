//
//  LockScreenViewModel.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/16/25.
//

import Foundation
import Observation

import RxSwift
import RxCocoa

final class LockScreenViewModel: ViewModelType {
    
    struct Input {
        let numberButtonTap: Observable<String>
        let deleteButtonTap: Observable<Void>
        let backButtonTap: Observable<Void>
    }
    
    struct Output {
        let enteredPasscodeLength: Driver<Int>
        let validationResult: Driver<PasscodeValidationResult>
        let shouldDismiss: Driver<Void>
        let shouldShakeIndicators: Driver<Void>
        let shouldResetPasscode: Driver<Void>
        let hapticFeedback: Driver<HapticType>
    }
    
    enum PasscodeValidationResult {
        case none
        case success
        case failure
    }
    
    enum HapticType {
        case light
        case success
        case error
    }
    
    private let disposeBag = DisposeBag()
    
    func transform(input: Input) -> Output {
        let maxPasscodeLength = 6
        let correctPasscode = "123456"
        
        let enteredPasscodeRelay = BehaviorRelay<String>(value: "")
        let validationResultRelay = PublishRelay<PasscodeValidationResult>()
        let shouldDismissRelay = PublishRelay<Void>()
        let shouldShakeIndicatorsRelay = PublishRelay<Void>()
        let shouldResetPasscodeRelay = PublishRelay<Void>()
        let hapticFeedbackRelay = PublishRelay<HapticType>()
        
        input.numberButtonTap
            .withLatestFrom(enteredPasscodeRelay) { number, currentPasscode in
                return (number, currentPasscode)
            }
            .filter { _, currentPasscode in
                return currentPasscode.count < maxPasscodeLength
            }
            .map { number, currentPasscode in
                return currentPasscode + number
            }
            .bind(to: enteredPasscodeRelay)
            .disposed(by: self.disposeBag)
        
        input.deleteButtonTap
            .withLatestFrom(enteredPasscodeRelay)
            .filter { !$0.isEmpty }
            .map { String($0.dropLast()) }
            .bind(to: enteredPasscodeRelay)
            .disposed(by: self.disposeBag)
        
        Observable.merge(
            input.numberButtonTap.map { _ in () },
            input.deleteButtonTap
        )
        .map { HapticType.light }
        .bind(to: hapticFeedbackRelay)
        .disposed(by: self.disposeBag)
        
        input.backButtonTap
            .bind(to: shouldDismissRelay)
            .disposed(by: self.disposeBag)
        
        enteredPasscodeRelay
            .filter { $0.count == maxPasscodeLength }
            .map { [weak self] passcode in
                guard self != nil else { return PasscodeValidationResult.failure }
                return passcode == correctPasscode ? .success : .failure
            }
            .bind(to: validationResultRelay)
            .disposed(by: self.disposeBag)
        
        validationResultRelay
            .subscribe(with: self) { owner, result in
                switch result {
                case .success:
                    hapticFeedbackRelay.accept(.success)
                case .failure:
                    hapticFeedbackRelay.accept(.error)
                    shouldShakeIndicatorsRelay.accept(())
                
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        shouldResetPasscodeRelay.accept(())
                    }
                case .none:
                    break
                }
            }
            .disposed(by: self.disposeBag)
        
        shouldResetPasscodeRelay
            .map { "" }
            .bind(to: enteredPasscodeRelay)
            .disposed(by: self.disposeBag)
        
        return Output(
            enteredPasscodeLength: enteredPasscodeRelay.map { $0.count }.asDriver(onErrorJustReturn: 0),
            validationResult: validationResultRelay.asDriver(onErrorJustReturn: .none),
            shouldDismiss: shouldDismissRelay.asDriver(onErrorJustReturn: ()),
            shouldShakeIndicators: shouldShakeIndicatorsRelay.asDriver(onErrorJustReturn: ()),
            shouldResetPasscode: shouldResetPasscodeRelay.asDriver(onErrorJustReturn: ()),
            hapticFeedback: hapticFeedbackRelay.asDriver(onErrorJustReturn: .light)
        )
    }
}
