import Foundation
import Combine
import SwiftUI

public final class LightingStudioViewModel: ObservableObject {
    public let appVM: AppViewModel
    
    @Published public var effect: LightingEffectType
    @Published public var primaryColor: Color
    @Published public var secondaryColor: Color
    @Published public var brightness: Double // 0.0 .. 1.0
    @Published public var waveDirection: UInt8
    @Published public var gameModeLED: Bool
    @Published public var macroModeLED: Bool
    @Published public var showSuccessAlert: Bool = false
    @Published public var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(appVM: AppViewModel) {
        self.appVM = appVM
        let cfg = appVM.profileManager.activeProfile.lighting
        self.effect = cfg.effect
        self.primaryColor = cfg.primaryColor.color
        self.secondaryColor = cfg.secondaryColor.color
        self.brightness = Double(cfg.brightness) / 255.0
        self.waveDirection = cfg.waveDirection
        self.gameModeLED = cfg.gameModeLED
        self.macroModeLED = cfg.macroModeLED
        
        // Listen to active profile changes
        appVM.profileManager.$activeProfile
            .sink { [weak self] profile in
                guard let self = self else { return }
                self.effect = profile.lighting.effect
                self.primaryColor = profile.lighting.primaryColor.color
                self.secondaryColor = profile.lighting.secondaryColor.color
                self.brightness = Double(profile.lighting.brightness) / 255.0
                self.waveDirection = profile.lighting.waveDirection
                self.gameModeLED = profile.lighting.gameModeLED
                self.macroModeLED = profile.lighting.macroModeLED
            }
            .store(in: &cancellables)
    }
    
    public func applyLighting() {
        let pRGB = primaryColor.toRGBColor()
        let sRGB = secondaryColor.toRGBColor()
        let brInt = UInt8(max(0, min(255, brightness * 255.0)))
        
        let newConfig = LightingConfiguration(
            effect: effect,
            primaryColor: pRGB,
            secondaryColor: sRGB,
            brightness: brInt,
            waveDirection: waveDirection,
            gameModeLED: gameModeLED,
            macroModeLED: macroModeLED
        )
        
        var profile = appVM.profileManager.activeProfile
        profile.lighting = newConfig
        appVM.profileManager.updateActiveProfile(profile)
        
        if appVM.discovery.isConnected {
            let res = appVM.lighting.applyConfiguration(newConfig)
            switch res {
            case .success:
                appVM.diagnostics.log(category: "Lighting", level: .success, message: "Applied \(effect.displayName) effect at \(Int(brightness * 100))% brightness", details: nil)
                showSuccessAlert = true
            case .failure(let err):
                errorMessage = err.localizedDescription
                appVM.diagnostics.log(category: "Lighting", level: .error, message: "Failed to apply lighting", details: err.localizedDescription)
            }
        }
    }
    
    public func resetToDefaults() {
        self.effect = .spectrum
        self.primaryColor = RGBColor.razerGreen.color
        self.secondaryColor = RGBColor.blue.color
        self.brightness = 224.0 / 255.0
        self.waveDirection = 1
        self.gameModeLED = false
        self.macroModeLED = false
        applyLighting()
    }
}

public extension Color {
    func toRGBColor() -> RGBColor {
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor.green
        let r = UInt8(max(0, min(255, nsColor.redComponent * 255.0)))
        let g = UInt8(max(0, min(255, nsColor.greenComponent * 255.0)))
        let b = UInt8(max(0, min(255, nsColor.blueComponent * 255.0)))
        return RGBColor(red: r, green: g, blue: b)
    }
}
