//
//  AXOMotionManager.swift
//  AXCameraOverlay
//
//  Created by Adi Mathew
//  RCPD@MSU
//

import CoreMotion

public struct AXOConstants {
    public static let DEFAULT_CENTERING_THRESHOLD: Int = 2 // degrees
}

public extension Notification.Name {
    static let didCenterGrid = Notification.Name("gridCenteredNotification")
    static let didUncenterGrid = Notification.Name("gridUncenteredNotification")
}

// I know @sandofsky isn't a fan of this "manager" style, but this is just a wrapper around MotionManager.
// The goal being to make code in AXOViewController cleaner.
public class AXOMotionManager {
    private let manager: CMMotionManager = CMMotionManager()
    
    private var lastStatus: AXOCenterStatus = .unknown

    /// A boolean that is used to determine whether to increase the threshold from the default 2 degrees if VO is turned on.
    public var thresholdSwitching: Bool = false
    
    public func startMotionUpdates(withVisualUpdates updates: @escaping (AXOOverlayView.Update)->(Bool?) ) {
        
        guard let queue: OperationQueue = OperationQueue.current else {
            return
        }
        
        // Start device motion updates to detect orientation
        self.manager.startDeviceMotionUpdates(to: queue) { (motion, error) in
            
            // Gravity data is used to detect whether crosshairs are centered
            guard let gravity: CMAcceleration = motion?.gravity else {
                return
            }
            
            var updateData: AXOOverlayView.Update = (.unknown, 0, 0)

            if self.thresholdSwitching {
                // This switch check is to slightly increase the threshold used for center checking.
                // This is done to prevent rapid repeated on/off sounds.
                // You can see what I mean by using default threshold in both branches
                let threshold: Int = AXOConstants.DEFAULT_CENTERING_THRESHOLD
                switch self.lastStatus {
                case .notCentered:
                    // Extract relevant data for visual updates from gravity
                    updateData = AXOCenterStatus.status(basedOnGravity: gravity)
                default:
                    // Extract relevant data for visual updates from gravity
                    updateData = AXOCenterStatus.status(basedOnGravity: gravity,
                                                        withThreshold: threshold + 1)
                }
            } else {
                updateData = AXOCenterStatus.status(basedOnGravity: gravity)
            }
            
            self.lastStatus = updateData.centerStatus
            
            
            OperationQueue.main.addOperation {
                // This only works for AXOVC centering.
                // NotificationCenter condition below can be easily done in the passed in block
                
                // Safe unwrap of centerstatus since it is only set when there is a change of status
                guard let taskStatus = updates(updateData) else {
                    return
                }
                
                if taskStatus {
                    NotificationCenter.default.post(name: .didCenterGrid,
                                                    object: self)
                } else {
                    NotificationCenter.default.post(name: .didUncenterGrid,
                                                    object: self)
                }

                
            }
        }
    }
    
    public func stopMotionUpdates() {
        self.manager.stopDeviceMotionUpdates()
    }
}
