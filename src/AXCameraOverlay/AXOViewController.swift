//
//  ViewController.swift
//  AXCameraOverlay
//
//  Created by Adi Mathew
//  RCPD@MSU
//

import UIKit
import AVFoundation

/*
 ------------------------------------
 
 This project is intended solely to serve as a demonstration of the type of
 interactive audio feedback I believe VoiceOver (VO) should provide when using a camera app focused on manual photography. I've only done very cursory testing with two low vision individuals using a variation of this project. So while the usability of the ideas described has received positive feedback, please consider this code a prototype and not reliable or tested for any sort of deployment. I am sharing it only to convey the following ideas and hope it helps you make Halide more VO friendly.
 
 The Level Grid in Halide is super useful for composition and I believe even more valuable from an accessibility standpoint, so the focus of this project is attempting to make its state more apparent to a VO.
 
 Focus:
    - Audio feedback when the grids align in either vertical or horizontal orientation. I am aware there is haptic feedback on devices that support it, but audio feedback is perceived with more clarity in the accessibility context
    - Thickening of the rotating grid when VoiceOver is turned on during app run. This assumes that if an individual is using a screen reader, they are relying on VO to confirm/support their visual cues. Having the crosshairs reflect this confirmation was received positively
    - Very slight increase in the threshold for detecting the centering status if VO is turned on. This is done to keep the centered state and prevent incessant audio feedback when the boundary is crossed. To clarify, the threshold to go from uncentered to centered remains the same as when VO is off; However, once a VO user centers the axes, we increase the threshold by 1 degree to make it "harder" to decenter. See AXOMotionManager and AXOCenterStatus for details
    - Using a different shade of the global tint color for the centering grid when the alignment crosshairs are overlaid on a bright preview image (such as snowy outdoors, etc.) For this prototype, I used a measure of Luma from the 4 corner pixels of the grid combined with the APEX brightness from each frames EXIF data. This was to use environmental brightness as a measure rather than screen pixel color. Either method will work just as well, with the former being a little more robust to exposure compensation when going from dark to light areas, etc. Ideally, this method would factor in the color of areas around the grid to provide the best contrast ratio (ratio of YUV Y intensity, however given our testing environment and my limited time I simply darkened the color)
     - While unnecessary if centering audio is the only sound effect, if there are more cues added, it might be worth adding a short intro to what each sound effect is when they are first toggled (if VO is active when activated).
 
 Limitations:
    - This project only focuses on the grid in vertical orientation.
    - Note that from the couple low vision folks I've tested with, they did not prefer feedback when the type of grid  changes (to/from the concentric circles), but would prefer that centering be the cue for audio feedback. This does not mean it is the best, but I thought I'd mention it. I personally think ignoring the switch between circles/grid is the right way too.
    - I've tried to make this code readable, but it is focused on skimming the comments and hence all immediately relevant code is in this ViewController. This was a change I made after using the project for testing and so a couple bugs have arisen such as some animations not working, etc. None of them affect the demonstration of features listed above.
 
 I'm sorry if there are parts that are unclear or rushed. I tried my best to get this done before the semester starts. Please do get in touch with me either via email or Twitter (@mxadx) and I'd be happy to clarify.
 
 Thanks for reading and making Halide VO friendly!
 -adi (1/16/2017)
 
 ------------------------------------
 */

/// An enum that should be updated with the current VoiceOver status
/// This enum is more of a convenience/sanity check when debugging, but it can also be
/// fleshed out into a proper wrapper around UIAccessibilityIsVoiceOverRunning() and
/// the .UIAccessibilityVoiceOverStatusDidChange Notification.
///
/// - on: VoiceOver was enabled on view appearing or via NotificationCentre
/// - off: VoiceOver was off on first appearance
/// - unknown: UIAccessibilityVoiceOverStatus was never read or notifications never observed.
public enum AXOVoiceOverStatus {
    case on
    case off
    case unknown
}

class AXOViewController: UIViewController {
    
    // ------------------------------------
    // MARK: - Noteworthy Private properties
    // Includes motion manager, sound, whether guides are enabled and current VoiceOver (VO) status
    
    // A wrapper around CMDeviceMotion/CMMotionManager so code here is succinct.
    private let motionManager: AXOMotionManager = AXOMotionManager()
    
    // Sound effects to play once when crosshairs are centered and uncentered
    private let centerSound: AXOSoundEffect = AXOSoundEffect(withSoundNamed: "positive.aiff")
    private let uncenterSound: AXOSoundEffect = AXOSoundEffect(withSoundNamed: "negative.aiff")
    
    // Use the didSet when the guides are toggled to alter any relevant accessibility properties
    private var isGuidesEnabled: Bool = true {
        didSet {
            if self.isGuidesEnabled {
                self.overlayView.isHidden = false
                self.overlayStaticBorder.isHidden = false
            } else {
                self.overlayView.isHidden = true
                self.overlayStaticBorder.isHidden = true
            }
            
            // This is unnecessary here, but may be useful in an actual app to let someone know that the grids have changed screen appearance even though inconsequentially
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self)
        }
    }
    
    // A var to store current VoiceOverStatus that is updated based on the UIAccessibilityNotificion in viewDidLoad
    private var currentVoiceOverStatus: AXOVoiceOverStatus = .unknown
    
    // AVCaptureSession and previewLayer
    private let session = AVCaptureSession()
    private var previewLayer = AVCaptureVideoPreviewLayer()
    
    // Use this property to change the color of the center grid when it is aligned
    fileprivate let crosshairTintColor: UIColor = UIColor(red: 254/155.0,
                                                          green: 254/255.0,
                                                          blue: 112/255.0,
                                                          alpha: 1.0)
    
    /*
     ------------------------------------
     MARK: - Outlets for the overlay view
     This view is a representation of the crosshair like grid when the device is
     oriented vertically, i.e lightning port pointed at ground.
    */
    @IBOutlet var overlayView: AXOOverlayView!
    @IBOutlet var overlayStaticBorder: AXOStaticView!
    
    // ------------------------------------
    // MARK: - UIViewController delegates
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up video capture and previewing delegate
        // This feed is also used to estimate the brightness and luma to simulate darkening of the grid if in very bright surroundings
        let testDevice = AVCaptureDevice.default(for: .video)
        do {
            let input = try AVCaptureDeviceInput(device: testDevice!)
            let
            output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self,
                                           queue: .main)
            
            self.session.addInput(input)
            self.session.addOutput(output)
            
            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
            self.previewLayer.videoGravity = .resizeAspectFill
            
        } catch {
            print(error)
        }
        
        /*
         
         Here, I used NotificationCenter to sign up to be alerted of 3 events:
            - Alignment of rotating grid to outlines (to play a sound)
            - Change of alignment status from aligned to askew (to play the 'uncenter' sound)
            - Was VO turned on or off during app run (to thicken the guides)
 
        */
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didCenterGrid),
                                               name: .didCenterGrid,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didUncenterGrid),
                                               name: .didUncenterGrid,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateVoiceOverStatus),
                                               name: .UIAccessibilityVoiceOverStatusDidChange,
                                               object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Start device motion updates.
        // All this block does is start updates and return whether the view is centered/aligned based on those updates.

        // The passed in data include whether it's centered,
        // rotation in x,y planes and z axis data as a 3 item tuple that the overlay handles.
        
        self.motionManager.startMotionUpdates(withVisualUpdates: { (data: AXOOverlayView.Update) in
            
            // Rotate the center level grid
            let visualCenterStatus = self.overlayView.updateView(with: data)
            
            // Update the grid if we switch from portrait to landscape or vice versa
            self.updateGridOrientation(withData: data)
            
            return visualCenterStatus
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Any time the view is visible, check whether VO is running and update its status
        self.updateVoiceOverStatus()
        
        // Set up the background view to be a video preview
        self.previewLayer.frame = self.view.bounds
        let
        testView = UIView(frame: self.view.bounds)
        testView.layer.addSublayer(self.previewLayer)
        self.view.insertSubview(testView, at: 0)
        self.session.startRunning()
    }
    
    // ------------------------------------
    // MARK: - Notification Center selectors
    
    /// This is called when the grids are centered with the outline
    @objc public func didCenterGrid() {
        // Again, the check for whether Guides are hidden should probably be in the View's class
        if self.currentVoiceOverStatus == .on  && self.isGuidesEnabled {
            self.centerSound.play()
        }
    }
    
    
    /// This is called when the grids go from centered to askew
    @objc public func didUncenterGrid() {
        // Again, the check for whether Guides are hidden should probably be in the View's class
        if self.currentVoiceOverStatus == .on && self.isGuidesEnabled {
            self.uncenterSound.play()
        }
    }
    
    
    /// This is called when VoiceOver is turned on or off during app run
    @objc public func updateVoiceOverStatus() {
        self.currentVoiceOverStatus = UIAccessibilityIsVoiceOverRunning() ? .on : .off
        
        // If VO was just turned on, thicken the moving grids border
        if self.currentVoiceOverStatus == .on {
            self.makeBordersThick()
            self.motionManager.thresholdSwitching = true
        } else {
            self.makeBordersThin()
            self.motionManager.thresholdSwitching = false
        }
    }
    
    // ------------------------------------
    // MARK: - IBActions for hiding/showing guide/grid.
    
    @IBAction func guidesButtonPressed(_ sender: UIButton) {
        self.isGuidesEnabled = !self.isGuidesEnabled
    }
    
    
    // ------------------------------------
    // MARK: - Boilerplate/Ignore these methods
    
    // Ignore: Outlets for the constraints to switch when in portrait/landscape
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    @IBOutlet var originalHeightConstraint: NSLayoutConstraint!
    @IBOutlet var widthConstraint: NSLayoutConstraint!
    @IBOutlet var originalWidthConstraint: NSLayoutConstraint!
    
    // Bool indicating whether the overlayView is using portrait or landscape constraints
    private var isUsingOriginalConstraint: Bool = true
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.motionManager.stopMotionUpdates()
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func makeBordersThick() {
        self.overlayView.defaultBorderWidth = 3.0
        self.overlayStaticBorder.borderOffset = 9.0
    }
    
    private func makeBordersThin() {
        self.overlayView.defaultBorderWidth = 1.0
        self.overlayStaticBorder.borderOffset = 3.0
    }
    
    private func updateGridOrientation(withData data: AXOOverlayView.Update) {
        let degrees: Int = Int(abs(data.rotationXY) * 180.0/Double.pi)
        
        if !((260...280 ~= degrees) || (80...100 ~= degrees)) {
            
            if !(self.isUsingOriginalConstraint) {
                self.view.removeConstraints([self.widthConstraint, self.heightConstraint])
                self.view.addConstraints([self.originalWidthConstraint, self.originalHeightConstraint])
            }
            
            self.widthConstraint.isActive = false
            self.heightConstraint.isActive = false
            
            self.originalWidthConstraint.isActive = true
            self.originalHeightConstraint.isActive = true
            
            self.isUsingOriginalConstraint = true
        } else {
            
            if self.isUsingOriginalConstraint {
                self.view.removeConstraints([self.originalWidthConstraint, self.originalHeightConstraint])
                self.view.addConstraints([self.widthConstraint, self.heightConstraint])
            }
            
            self.widthConstraint.isActive = true
            self.heightConstraint.isActive = true
            
            self.originalWidthConstraint.isActive = false
            self.originalHeightConstraint.isActive = false
            
            self.isUsingOriginalConstraint = false
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    // ------------------------------------
}

// ------------------------------------
// MARK:- AVCaptureVideoData Buffer delegate
// Extension where we check each frame captured for brightness and luma
// If the scene is brighter than a certain threshold, we darken the centering grids color
// Note that this is just one approach to ensuring the grids are visible. Another would be to simply contrast on-screen pixel color contrast ratios. However, I decided to prototype and test this method since it avoids  the compensation of exposure that happens when transitioning from light to dark environments

extension AXOViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        // Use the EXIF/APEX brightness measure
        guard let dict = CMGetAttachment(sampleBuffer,
                                         kCGImagePropertyExifDictionary,
                                         nil) else { return }
        
        guard let brightness: Double = dict["BrightnessValue"] as? Double else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        guard let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else { return }
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let byteBuffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        // Using default 420YpCbCr8BiPlanarVideoRange
        // This is using a single pixel's luma from the center of the preview.
        let lumaCenter = byteBuffer[540 * bytesPerRow + 960]
        
        /*
        // There's more efficient ways to calculate an average luma over the grids area.
        // We essentially want to combine a measure of environment brightness with screen pixel contrast to ensure the grids color is discernible against any bright colors present.
        let luma1 = byteBuffer[270 * bytesPerRow + 480]
        let luma2 = byteBuffer[810 * bytesPerRow + 480]
        let luma3 = byteBuffer[270 * bytesPerRow + 1440]
        let luma4 = byteBuffer[810 * bytesPerRow + 1440]
        let lumaAverage = (luma1 + luma2 + luma3 + luma4 + lumaCenter)/5
        */
        
        // Check whether it is bright or dim based on the threshold for luma (16-250) and brightness (-/+)
        let status: AXOBrightnessStatus = AXOBrightnessStatus.status(basedOnLuma: Int(lumaCenter),
                                                                     brightness: brightness,
                                                                     thresholds: (120, 2.5))
        
        switch status {
        case .light:
            self.overlayView.centeredColor = self.crosshairTintColor.darkerColor()!
        default:
            self.overlayView.centeredColor = self.crosshairTintColor
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    }
    
}

