//
//  AlertAction.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/18/25.
//

import UIKit

struct AlertModel {
    let title: String
    let message: String
    let style: UIAlertController.Style
    let actions: [AlertAction]
    let completion: (() -> Void)?
    
    init(
        title: String,
        message: String,
        style: UIAlertController.Style = .alert,
        actions: [AlertAction] = [AlertAction(title: "확인", style: .default)],
        completion: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.style = style
        self.actions = actions
        self.completion = completion
    }
    
    static let defaultAlert = AlertModel(title: "", message: "")
}

struct AlertAction {
    let title: String
    let style: UIAlertAction.Style
    let handler: (() -> Void)?
    
    init(title: String,
         style: UIAlertAction.Style = .default,
         handler: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}
