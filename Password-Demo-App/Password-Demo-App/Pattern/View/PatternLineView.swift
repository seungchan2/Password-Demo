//
//  PatternLineView.swift
//  Password-Demo-App
//
//  Created by MEGA_Mac on 9/16/25.
//

import UIKit

import SnapKit

final class PatternLineView: UIView {
    public var connectedPoints: [CGPoint] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var dragLocation: CGPoint? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        self.setStroke()
    }
    
    private func setStroke() {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        guard self.connectedPoints.count > 0 else { return }
        
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(3.0)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        if self.connectedPoints.count > 1 {
            for i in 1..<self.connectedPoints.count {
                context.move(to: self.connectedPoints[i-1])
                context.addLine(to: self.connectedPoints[i])
            }
        }
        
        if let lastPoint = self.connectedPoints.last, let dragPoint = dragLocation {
            context.move(to: lastPoint)
            context.addLine(to: dragPoint)
        }
        
        context.strokePath()
    }
}
