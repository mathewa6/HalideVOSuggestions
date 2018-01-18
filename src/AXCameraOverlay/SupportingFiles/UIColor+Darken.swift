//
//  UIColor+Darken.swift
//  AXCameraOverlay
//
//  Created by Adi Mathew
//  RCPD@MSU
//

import UIKit

extension UIColor {
    public func darkerColor(byFactor factor: CGFloat = 0.87) -> UIColor? {
        var
        h: CGFloat = 0,
        s: CGFloat = 0,
        b: CGFloat = 0,
        a: CGFloat = 0
        
        if self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return UIColor(hue: h, saturation: s, brightness: (b * factor), alpha: a)
        }
        
        return nil
    }
}
