//
//  PatternViewController.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/16/25.

import UIKit

import RxSwift
import RxCocoa
import SnapKit
// MARK: - PatternViewController (MVVM)

final class PatternViewController: UIViewController {
        
    private let viewModel: PatternViewModel
    private let disposeBag = DisposeBag()
        
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let statusLabel = UILabel()
    private let securityInfoLabel = UILabel()
    private let patternContainerView = UIView()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private let patternLineView = PatternLineView()
    private var patternDots: [PatternDotView] = []
    
    private let buttonStackView = UIStackView()
    private let deletePatternButton = UIButton()
    private let securityInfoButton = UIButton()
    
    
    private var patternPoints: [PatternPoint] = []
    private var currentPattern: [Int] = []
    private var isDrawing: Bool = false
    
    private let gridSize = 3
    private let dotSpacing: CGFloat = 120
    
    private let patternCompletedRelay = PublishRelay<[Int]>()
    private let timerRelay = PublishRelay<Void>()
        
    init(viewModel: PatternViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience init(patternManager: SecurePatternManagerProtocol = SecurePatternManagerFactory.createDefault()) {
        let viewModel = PatternViewModel(patternManager: patternManager)
        self.init(viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        let patternManager = SecurePatternManagerFactory.createDefault()
        self.viewModel = PatternViewModel(patternManager: patternManager)
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupViews()
        setupPatternGrid()
        setupGestures()
        bind()
        startTimer()
    }
    
    private func bind() {
        let input = PatternViewModel.Input(
            viewDidLoad: .just(()),
            patternCompleted: patternCompletedRelay.asObservable(),
            deletePatternTapped: deletePatternButton.rx.tap.asObservable(),
            showSecurityInfoTapped: securityInfoButton.rx.tap.asObservable(),
            backButtonTapped: backButton.rx.tap.asObservable(),
            timerTick: timerRelay.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.uiMode
            .drive(with: self) { owner, mode in
                owner.updateUI(for: mode)
            }
            .disposed(by: disposeBag)
        
        output.statusText
            .drive(statusLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.statusColor
            .drive(statusLabel.rx.textColor)
            .disposed(by: disposeBag)
        
        output.securityInfoText
            .drive(securityInfoLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.isPatternInteractionEnabled
            .drive(patternContainerView.rx.isUserInteractionEnabled)
            .disposed(by: disposeBag)
        
        output.isDeleteButtonHidden
            .drive(deletePatternButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        output.showAlert
            .drive(with: self) { owner, model in
                owner.showAlert(model)
            }
            .disposed(by: disposeBag)
        
        output.dismissViewController
            .drive(with: self) { owner, _ in
                owner.dismissViewController()
            }
            .disposed(by: disposeBag)
        
        output.shouldResetPattern
            .delay(.milliseconds(1500))
            .drive(with: self) { owner, _ in
                owner.resetPattern()
            }
            .disposed(by: disposeBag)
    }
    
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerRelay.accept(())
        }
    }
    
    private func setupViews() {
        view.backgroundColor = .black
        
        view.addSubview(backButton)
        backButton.snp.makeConstraints {
            $0.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.width.height.equalTo(44)
        }
        
        view.addSubview(titleLabel)
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            $0.centerX.equalToSuperview()
        }
        
        view.addSubview(subtitleLabel)
        subtitleLabel.textColor = .lightGray
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textAlignment = .center
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
        }
        
        view.addSubview(statusLabel)
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        view.addSubview(securityInfoLabel)
        securityInfoLabel.textColor = .systemGray
        securityInfoLabel.font = UIFont.systemFont(ofSize: 12)
        securityInfoLabel.textAlignment = .center
        securityInfoLabel.numberOfLines = 0
        securityInfoLabel.snp.makeConstraints {
            $0.top.equalTo(statusLabel.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        view.addSubview(patternContainerView)
        patternContainerView.backgroundColor = .clear
        patternContainerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(400)
        }
        
        patternContainerView.addSubview(patternLineView)
        patternLineView.backgroundColor = .clear
        patternLineView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        setupManagementButtons()
    }
    
    private func setupManagementButtons() {
        view.addSubview(buttonStackView)
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 20
        
        deletePatternButton.setTitle("패턴 삭제", for: .normal)
        deletePatternButton.setTitleColor(.systemRed, for: .normal)
        deletePatternButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
        deletePatternButton.layer.cornerRadius = 8
        
        securityInfoButton.setTitle("보안 상태", for: .normal)
        securityInfoButton.setTitleColor(.systemGreen, for: .normal)
        securityInfoButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
        securityInfoButton.layer.cornerRadius = 8
        
        buttonStackView.addArrangedSubview(deletePatternButton)
        buttonStackView.addArrangedSubview(securityInfoButton)
        
        buttonStackView.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            $0.leading.trailing.equalToSuperview().inset(40)
            $0.height.equalTo(44)
        }
    }
    
    private func setupPatternGrid() {
        patternPoints = []
        patternDots = []
        
        let containerSize: CGFloat = 400
        let startOffset = (containerSize - CGFloat(gridSize - 1) * dotSpacing) / 2
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let id = row * gridSize + col
                let x = startOffset + CGFloat(col) * dotSpacing
                let y = startOffset + CGFloat(row) * dotSpacing
                
                let point = PatternPoint(id: id, position: CGPoint(x: x, y: y))
                patternPoints.append(point)
                
                let dotView = PatternDotView()
                patternContainerView.addSubview(dotView)
                dotView.snp.makeConstraints {
                    $0.center.equalTo(CGPoint(x: x, y: y))
                    $0.size.equalTo(60)
                }
                
                patternDots.append(dotView)
            }
        }
    }
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        patternContainerView.addGestureRecognizer(panGesture)
    }
    
    @objc
    private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: patternContainerView)
        
        switch gesture.state {
        case .began:
            startPattern(at: location)
        case .changed:
            updatePattern(at: location)
        case .ended, .cancelled:
            endPattern()
        default:
            break
        }
    }
    
    private func startPattern(at location: CGPoint) {
        guard let pointIndex = findPointAt(location: location) else { return }
        
        resetPattern()
        
        currentPattern.append(patternPoints[pointIndex].id)
        patternPoints[pointIndex].isConnected = true
        patternDots[pointIndex].isConnected = true
        isDrawing = true
        
        updatePatternLine()
    }
    
    private func updatePattern(at location: CGPoint) {
        guard isDrawing else { return }
        
        patternLineView.dragLocation = location
        
        if let pointIndex = findPointAt(location: location) {
            let pointId = patternPoints[pointIndex].id
            
            if !currentPattern.contains(pointId) {
                currentPattern.append(pointId)
                patternPoints[pointIndex].isConnected = true
                patternDots[pointIndex].isConnected = true
                updatePatternLine()
            }
        }
    }
    
    private func endPattern() {
        guard !currentPattern.isEmpty else { return }
        
        isDrawing = false
        patternLineView.dragLocation = nil
        
        patternCompletedRelay.accept(currentPattern)
    }
        
    private func updateUI(for mode: UIMode) {
        titleLabel.text = mode.title
        subtitleLabel.text = mode.subtitle
    }
    
    private func showAlert(_ alertModel: AlertModel) {
        let alert = UIAlertController(
            title: alertModel.title,
            message: alertModel.message,
            preferredStyle: alertModel.style
        )
        
        for action in alertModel.actions {
            let alertAction = UIAlertAction(
                title: action.title,
                style: action.style
            ) { _ in
                action.handler?()
                alertModel.completion?()
            }
            alert.addAction(alertAction)
        }
        
        present(alert, animated: true)
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
    
    
    private func updatePatternLine() {
        var connectedPoints: [CGPoint] = []
        for patternId in currentPattern {
            if let point = patternPoints.first(where: { $0.id == patternId }) {
                connectedPoints.append(point.position)
            }
        }
        patternLineView.connectedPoints = connectedPoints
    }
    
    private func resetPattern() {
        currentPattern.removeAll()
        patternLineView.connectedPoints = []
        patternLineView.dragLocation = nil
        
        for index in patternPoints.indices {
            patternPoints[index].isConnected = false
            patternDots[index].isConnected = false
        }
    }
    
    private func findPointAt(location: CGPoint) -> Int? {
        for (index, point) in patternPoints.enumerated() {
            let distance = sqrt(
                pow(location.x - point.position.x, 2) +
                pow(location.y - point.position.y, 2)
            )
            
            if distance <= 35 {
                return index
            }
        }
        return nil
    }
}
