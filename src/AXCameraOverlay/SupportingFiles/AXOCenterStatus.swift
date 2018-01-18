//
//  AXOCenterStatus.swift
//  AXCameraOverlay
//
//  Created by Adi Mathew
//  RCPD@MSU
//

import CoreMotion
import UIKit

public enum AXOCenterStatus {
    case centered
    case notCentered
    case unknown
    
    // Debatable, but this threshold could be increased to 3 or 4 when VoiceOver is enabled.
    public static func status(basedOnGravity value: CMAcceleration,
                              withThreshold threshold: Int = AXOConstants.DEFAULT_CENTERING_THRESHOLD) -> AXOOverlayView.Update {
        let rotation: Double = atan2(value.x, value.y) - .pi
        let degrees: Int = Int(abs(rotation) * 180.0/Double.pi)
        let centered: Bool = degrees % 90 < threshold || degrees % 90 > (90 - threshold)
        let z: Double = value.z
        
        if centered { return (.centered, rotation, z) }
        else { return (.notCentered, rotation, z) }
    }
}
