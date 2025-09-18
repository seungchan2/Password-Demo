import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class LockScreenViewController: UIViewController {
    
    private let viewModel: LockScreenViewModel
    private let disposeBag = DisposeBag()
    private let maxPasscodeLength = 6
   
    private let backgroundView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "암호 입력"
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textAlignment = .center
        return label
    }()
    
    private let passcodeIndicatorStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 20
        return stackView
    }()
    
    private var passcodeIndicators: [UIView] = []
    
    private let numberPadStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 15
        return stackView
    }()
    
    private let numberButtonTapSubject = PublishSubject<String>()
    private let deleteButtonTapSubject = PublishSubject<Void>()
    
    init(viewModel: LockScreenViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideNavigationBar()
        self.setupUI()
        self.setupConstraints()
        self.setupGradientBackground()
        self.bindViewModel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.hideNavigationBar()
    }
    
    private func hideNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupUI() {
        view.backgroundColor = .black
        
        /// 암호 인디케이터 생성
        for _ in 0..<self.maxPasscodeLength {
            let indicator = UIView()
            indicator.backgroundColor = .clear
            indicator.layer.borderColor = UIColor.white.cgColor
            indicator.layer.borderWidth = 1.5
            indicator.layer.cornerRadius = 7
            self.passcodeIndicators.append(indicator)
            self.passcodeIndicatorStackView.addArrangedSubview(indicator)
        }
        
        self.setupNumberPad()
        
        self.view.addSubview(self.backgroundView)
        self.view.addSubview(self.backButton)
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.passcodeIndicatorStackView)
        self.view.addSubview(self.numberPadStackView)
    }
    
    private func setupNumberPad() {
        let numbers = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"]
        ]
        
        for row in numbers {
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.distribution = .equalSpacing
            rowStackView.alignment = .center
            rowStackView.spacing = 25
            
            for number in row {
                let button = self.createNumberButton(number: number)
                rowStackView.addArrangedSubview(button)
            }
            
            self.numberPadStackView.addArrangedSubview(rowStackView)
        }
        
        let lastRowStackView = UIStackView()
        lastRowStackView.axis = .horizontal
        lastRowStackView.distribution = .equalSpacing
        lastRowStackView.alignment = .center
        lastRowStackView.spacing = 25
        
        let emptyView = UIView()
        lastRowStackView.addArrangedSubview(emptyView)
        
        let zeroButton = self.createNumberButton(number: "0")
        lastRowStackView.addArrangedSubview(zeroButton)
        
        let deleteButton = self.createDeleteButton()
        lastRowStackView.addArrangedSubview(deleteButton)
        
        self.numberPadStackView.addArrangedSubview(lastRowStackView)
    }
    
    private func createNumberButton(number: String) -> UIButton {
        let button = UIButton(type: .custom)
        
        button.setTitle(number, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 32, weight: .regular)
        
        button.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        button.layer.cornerRadius = 40
        
        button.rx.tap
            .map { number }
            .bind(to: self.numberButtonTapSubject)
            .disposed(by: self.disposeBag)
        
        self.setupButtonTouchAnimation(button)
        
        return button
    }
    
    private func createDeleteButton() -> UIButton {
        let button = UIButton(type: .custom)
        
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        let deleteImage = UIImage(systemName: "delete.left.fill", withConfiguration: config)
        button.setImage(deleteImage, for: .normal)
        button.tintColor = .white
        
        button.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        button.layer.cornerRadius = 40
        
        button.rx.tap
            .bind(to: self.deleteButtonTapSubject)
            .disposed(by: self.disposeBag)
        
        self.setupButtonTouchAnimation(button)
        
        return button
    }
    
    private func setupButtonTouchAnimation(_ button: UIButton) {
        button.rx.controlEvent(.touchDown)
            .subscribe(with: self) { owner, _ in
                UIView.animate(withDuration: 0.1) {
                    button.alpha = 0.5
                    button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                }
            }
            .disposed(by: self.disposeBag)
        
        Observable.merge(
            button.rx.controlEvent(.touchUpInside).asObservable(),
            button.rx.controlEvent(.touchUpOutside).asObservable(),
            button.rx.controlEvent(.touchCancel).asObservable()
        )
        .subscribe(with: self) { owner, _ in
            UIView.animate(withDuration: 0.1) {
                button.alpha = 1.0
                button.transform = .identity
            }
        }
        .disposed(by: self.disposeBag)
    }
    
    private func setupConstraints() {
        self.backgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        self.backButton.snp.makeConstraints {
            $0.leading.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.width.height.equalTo(44)
        }
        
        self.titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().multipliedBy(0.4)
        }
        
        self.passcodeIndicatorStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(30)
            $0.height.equalTo(14)
        }
        
        self.passcodeIndicators.forEach { indicator in
            indicator.snp.makeConstraints {
                $0.size.equalTo(14)
            }
        }
        
        self.numberPadStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(self.passcodeIndicatorStackView.snp.bottom).offset(60)
            $0.width.equalTo(300)
            $0.height.equalTo(400)
        }
        
        self.numberPadStackView.arrangedSubviews.forEach { rowStack in
            if let stack = rowStack as? UIStackView {
                stack.arrangedSubviews.forEach { view in
                    if let button = view as? UIButton {
                        button.snp.makeConstraints {
                            $0.size.equalTo(80)
                        }
                    } else {
                        view.snp.makeConstraints {
                            $0.size.equalTo(80)
                        }
                    }
                }
            }
        }
    }
    
    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        
        gradientLayer.colors = [
            UIColor(red: 0.2, green: 0.1, blue: 0.15, alpha: 1.0).cgColor,
            UIColor(red: 0.4, green: 0.2, blue: 0.3, alpha: 1.0).cgColor,
            UIColor(red: 0.3, green: 0.15, blue: 0.35, alpha: 1.0).cgColor,
            UIColor(red: 0.1, green: 0.05, blue: 0.1, alpha: 1.0).cgColor
        ]
        
        gradientLayer.locations = [0.0, 0.3, 0.7, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        self.backgroundView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func bindViewModel() {
        let input = LockScreenViewModel.Input(
            numberButtonTap: numberButtonTapSubject.asObservable(),
            deleteButtonTap: deleteButtonTapSubject.asObservable(),
            backButtonTap: backButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.enteredPasscodeLength
            .drive(with: self) { owner, length in
                owner.updatePasscodeIndicators(length: length)
            }
            .disposed(by: self.disposeBag)
        
        output.validationResult
            .drive(with: self) { owner, result in
                switch result {
                case .success:
                    print("잠금 해제 성공!")
                case .failure:
                    print("잠금 해제 실패")
                case .none:
                    break
                }
            }
            .disposed(by: self.disposeBag)
        
        output.shouldDismiss
            .drive(with: self) { owner, _ in
                owner.dismissViewController()
            }
            .disposed(by: self.disposeBag)
        
        output.shouldShakeIndicators
            .drive(with: self) { owner, _ in
                owner.shakePasscodeIndicators()
            }
            .disposed(by: self.disposeBag)
        
        output.hapticFeedback
            .drive(with: self) { owner, hapticType in
                switch hapticType {
                case .light:
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                case .success:
                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.success)
                case .error:
                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.error)
                }
            }
            .disposed(by: self.disposeBag)
    }
    
    private func updatePasscodeIndicators(length: Int) {
        for (index, indicator) in self.passcodeIndicators.enumerated() {
            UIView.animate(withDuration: 0.2) {
                if index < length {
                    indicator.backgroundColor = .white
                } else {
                    indicator.backgroundColor = .clear
                }
            }
        }
    }
    
    private func shakePasscodeIndicators() {
        let animation = CAKeyframeAnimation(keyPath: "position.x")
        animation.values = [0, -10, 10, -10, 10, 0]
        animation.keyTimes = [0, 0.2, 0.4, 0.6, 0.8, 1]
        animation.duration = 0.4
        animation.isAdditive = true
        
        self.passcodeIndicatorStackView.layer.add(animation, forKey: "shake")
    }
    
    private func dismissViewController() {
        if let navigationController = navigationController {
            if navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            } else {
                dismiss(animated: true)
            }
        } else {
            dismiss(animated: true)
        }
    }
}
