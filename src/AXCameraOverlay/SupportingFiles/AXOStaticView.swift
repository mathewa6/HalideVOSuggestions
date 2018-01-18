//
//  AXOStaticView.swift
//  AXCameraOverlay
//
//  Created by Adi Mathew
//  RCPD@MSU
//

import UIKit

class AXOStaticView: UIView {
    
    public var borderOffset: CGFloat = 1.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup() {
        // The following can be removed if there is no video preview
        self.isOpaque = false
        self.backgroundColor = .clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.setNeedsDisplay()
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // Drawing code
        guard let context: CGContext = UIGraphicsGetCurrentContext() else { return }
        
        // Draw 4 gridlines around the center, where we'll draw the moving overlay
        let center: CGPoint = CGPoint(x: rect.origin.x + rect.width/2,
                                      y: rect.origin.y + rect.height/2)
        
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(1.0)
        
        context.move(to: CGPoint(x: center.x - rect.width/4 + self.borderOffset/2, y: 0))
        context.addLine(to: CGPoint(x: center.x - rect.width/4 + self.borderOffset/2, y: rect.height))
        
        context.move(to: CGPoint(x: center.x + rect.width/4 - self.borderOffset/2, y: 0))
        context.addLine(to: CGPoint(x: center.x + rect.width/4 - self.borderOffset/2, y: rect.height))

        context.move(to: CGPoint(x: 0, y: center.y - rect.height/4 + self.borderOffset/2))
        context.addLine(to: CGPoint(x: rect.width, y: center.y - rect.height/4 + self.borderOffset/2))

        context.move(to: CGPoint(x: 0, y: center.y + rect.height/4 - self.borderOffset/2))
        context.addLine(to: CGPoint(x: rect.width, y: center.y + rect.height/4 - self.borderOffset/2))
        
        context.strokePath()
    }

}
