import Foundation
import SwiftUI

public enum LightingEffectType: String, Codable, CaseIterable {
    case `static` = "static"
    case breathingSingle = "breathingSingle"
    case breathingDual = "breathingDual"
    case breathingRandom = "breathingRandom"
    case spectrum = "spectrum"
    case wave = "wave"
    case off = "off"
    
    public var displayName: String {
        switch self {
        case .static: return "Static"
        case .breathingSingle: return "Breathing (Single Color)"
        case .breathingDual: return "Breathing (Dual Color)"
        case .breathingRandom: return "Breathing (Random Color)"
        case .spectrum: return "Spectrum Cycling"
        case .wave: return "Wave Effect"
        case .off: return "Off"
        }
    }
}

public struct RGBColor: Codable, Equatable, Hashable {
    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8
    
    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }
    
    public var color: Color {
        Color(
            red: Double(red) / 255.0,
            green: Double(green) / 255.0,
            blue: Double(blue) / 255.0
        )
    }
    
    public static let razerGreen = RGBColor(red: 0, green: 255, blue: 0)
    public static let red = RGBColor(red: 255, green: 0, blue: 0)
    public static let blue = RGBColor(red: 0, green: 128, blue: 255)
    public static let yellow = RGBColor(red: 255, green: 215, blue: 0)
    public static let purple = RGBColor(red: 180, green: 0, blue: 255)
    public static let white = RGBColor(red: 255, green: 255, blue: 255)
}

public struct LightingConfiguration: Codable, Equatable {
    public var effect: LightingEffectType
    public var primaryColor: RGBColor
    public var secondaryColor: RGBColor
    public var brightness: UInt8 // 0..255
    public var waveDirection: UInt8 // 1 = left, 2 = right
    public var gameModeLED: Bool
    public var macroModeLED: Bool
    
    public init(
        effect: LightingEffectType = .spectrum,
        primaryColor: RGBColor = .razerGreen,
        secondaryColor: RGBColor = .blue,
        brightness: UInt8 = 224,
        waveDirection: UInt8 = 1,
        gameModeLED: Bool = false,
        macroModeLED: Bool = false
    ) {
        self.effect = effect
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.brightness = brightness
        self.waveDirection = waveDirection
        self.gameModeLED = gameModeLED
        self.macroModeLED = macroModeLED
    }
}
