//
//  AXOSoundEffect.swift
//  AXCameraOverlay
//
//  Created by Adi Mathew
//  RCPD@MSU
//

import UIKit
import AudioToolbox.AudioServices

class AXOSoundEffect {
    private var soundID: SystemSoundID = 0
    
    public init(withSoundNamed filename: String) {
        let components = filename.components(separatedBy: ".")
        guard let name = components.first else { return }
        guard let ext = components.last else { return }
        guard let url = Bundle.main.url(forResource: name,
                                        withExtension: ext) else { return }
        
        var tempID: SystemSoundID = 0
        let error: OSStatus = AudioServicesCreateSystemSoundID(url as CFURL, &tempID)
        
        guard error == kAudioServicesNoError else { return }
        
        self.soundID = tempID
    }
    
    public func play() {
        AudioServicesPlaySystemSound(self.soundID)
    }
    
    deinit {
        AudioServicesDisposeSystemSoundID(self.soundID)
    }
}
