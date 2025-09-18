//
//  PatternDotView.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/16/25.
//

import UIKit

import SnapKit

final class PatternDotView: UIView {
    private let outerCircle = UIView()
    private let innerCircle = UIView()
    
    var isConnected: Bool = false {
        didSet {
            self.updateAppearance()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        self.backgroundColor = .clear
        
        self.addSubview(self.outerCircle)
        self.outerCircle.layer.cornerRadius = 25
        self.outerCircle.layer.borderWidth = 2
        self.outerCircle.layer.borderColor = UIColor.white.cgColor
        self.outerCircle.backgroundColor = .clear
        
        self.outerCircle.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(50)
        }
        
        self.addSubview(self.innerCircle)
        self.innerCircle.layer.cornerRadius = 8
        self.innerCircle.backgroundColor = .clear
        
        self.innerCircle.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(16)
        }
    }
    
    private func updateAppearance() {
        UIView.animate(withDuration: 0.2) {
            if self.isConnected {
                self.outerCircle.backgroundColor = UIColor.systemBlue
                self.innerCircle.backgroundColor = UIColor.white
                self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            } else {
                self.outerCircle.backgroundColor = .clear
                self.innerCircle.backgroundColor = .clear
                self.transform = .identity
            }
        }
    }
}
