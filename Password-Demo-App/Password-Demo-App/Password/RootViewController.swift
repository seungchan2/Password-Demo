//
//  RootViewController.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/16/25.
//

import UIKit

import RxSwift
import RxCocoa
import SnapKit

final class RootViewController: UIViewController {
    
    private let goLockButton = UIButton()
    private let goPatternButton = UIButton()
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUI()
        self.setStyle()
        self.bind()
    }
    
    private func setUI() {
        self.view.addSubview(self.goLockButton)
        self.view.addSubview(self.goPatternButton)
        
        self.goLockButton.snp.makeConstraints {
            $0.height.equalTo(48)
            $0.width.equalTo(100)
            $0.leading.equalToSuperview().inset(10)
            $0.centerY.equalToSuperview()
        }
        
        self.goPatternButton.snp.makeConstraints {
            $0.height.equalTo(48)
            $0.width.equalTo(100)
            $0.trailing.equalToSuperview().inset(10)
            $0.centerY.equalToSuperview()
        }
    }
    
    private func setStyle() {
        self.view.backgroundColor = .white
        self.goLockButton.backgroundColor = .gray
        self.goPatternButton.backgroundColor = .yellow
    }
    
    private func bind() {
        self.goLockButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.goLockViewController()
            }
            .disposed(by: self.disposeBag)
        
        self.goPatternButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.goPatternViewController()
            }
            .disposed(by: self.disposeBag)
    }
    
    private func goLockViewController() {
        let viewController = LockScreenViewController(viewModel: LockScreenViewModel())
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func goPatternViewController() {
        let viewController = PatternViewController()
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}
