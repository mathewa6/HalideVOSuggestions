//
//  AXOBrightnessStatus.swift
//  AXCameraOverlay
//
//  Created by Adi Mathew
//  RCPD@MSU
//

import UIKit

public enum AXOBrightnessStatus {
    case light
    case dark
    case unknown
    
    public static func status(basedOnLuma luma: Int,
                       brightness: Double,
                       thresholds: (tLuma: Int, tBrightness: Double)) -> AXOBrightnessStatus {
        
        if brightness > thresholds.tBrightness && luma > thresholds.tLuma {
            return .light
        } else {
            return .dark
        }
    }
}
