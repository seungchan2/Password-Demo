//
//  ViewModelType.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/16/25.
//

import Foundation

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input) -> Output
}
