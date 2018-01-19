//
//  AXOBrightnessStatus.swift
//  AXCameraOverlay
//
//  Created by Adi Mathew
//  RCPD@MSU
//

import UIKit

/// An enum used to depict how bright the environment is, based on incoming frames
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
