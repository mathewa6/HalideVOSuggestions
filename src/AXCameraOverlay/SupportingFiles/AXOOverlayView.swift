//
//  AXOverlayView.swift
//  AXCameraOverlay
//
//  Created by Adi Mathew
//  RCPD@MSU
//

import UIKit

public class AXOOverlayView: UIView {

    private var centerStatus: AXOCenterStatus = .unknown
    
    private var flipped: Bool = false
    
    private let animationDuration: Double = 0.33
    
    private let zThreshold: CGFloat = 0.84
    
    private let alphaAnimator: UIViewPropertyAnimator = UIViewPropertyAnimator(duration: 0.25,
                                                                               curve: .easeInOut)
    
    public var centeredColor: UIColor = .green {
        didSet {
//            self.layer.borderColor = self.layerColor(forStatus: self.centerStatus).cgColor
//            self.setNeedsDisplay()
            
            let newColor: UIColor = self.layerColor(forStatus: self.centerStatus)
            self.animateLayerChange(toColor: newColor)
        }
    }
    
    public var defaultBorderWidth: CGFloat = 1.0 {
        didSet {
            self.layer.borderWidth = self.defaultBorderWidth
            self.setNeedsDisplay()
        }
    }

    public typealias Update = (centerStatus: AXOCenterStatus, rotationXY:Double, z: Double)
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup() {
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.borderWidth = self.defaultBorderWidth
        self.layer.cornerRadius = 1.0
        
        self.backgroundColor = .clear
        self.isOpaque = false
        
        self.alphaAnimator.isInterruptible = true
        self.alphaAnimator.addAnimations {
            self.alpha = 0.0
        }
    }
    
    private func layerColor(forStatus status: AXOCenterStatus) -> UIColor {
        if status == .centered { return self.centeredColor.withAlphaComponent(0.9) }
        
        return UIColor.lightGray
    }
    
    private func animateLayerChange(toColor color: UIColor) {
        
        let
        animation: CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
        animation.fromValue = self.layer.borderColor
        animation.toValue = color.cgColor
        animation.duration = self.animationDuration
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        self.layer.add(animation, forKey: "borderColorChange")
        self.layer.borderColor = color.cgColor

    }
    
    // For demonstration purposes return a boolean indicating if centering code has actually run.
    public func updateView(with data: Update) -> Bool? {
        
        let (status, rotation, gravityZ) = data

        self.centerStatus = status
        self.transform = CGAffineTransform(rotationAngle: CGFloat(rotation))
        
        // Check Z axis gravity to make vertical overlay disappear when laying flat
        let normedZ: CGFloat = CGFloat(abs(gravityZ))
        if normedZ < self.zThreshold {
            self.alphaAnimator.fractionComplete = 0
        } else {
            self.alphaAnimator.fractionComplete = (normedZ - self.zThreshold) * 10
            return nil
        }
        
        // If vertical, check whether it is aligned to display border
        if status == .centered {
            guard !flipped else {
                return nil
            }
            
            self.animateLayerChange(toColor: self.layerColor(forStatus: self.centerStatus))
            
            self.layer.borderWidth = 2 * defaultBorderWidth
            self.layer.cornerRadius = 3.0
            
            flipped = true
        } else {
            guard flipped else {
                return nil
            }
            
            self.animateLayerChange(toColor: self.layerColor(forStatus: self.centerStatus))
            
            self.layer.borderWidth = 1 * defaultBorderWidth
            self.layer.cornerRadius = 1.0
            
            flipped = false
        }
        
        // Note that this is reached only once when there is a change in status, thanks to the flipped var
        return (status == .centered)
    }
}
