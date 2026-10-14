import Foundation

public enum KeyActionType: String, Codable, CaseIterable {
    case remapKey = "remapKey"
    case modifierCombo = "modifierCombo"
    case mediaControl = "mediaControl"
    case launchApp = "launchApp"
    case macro = "macro"
    case disable = "disable"
    
    public var displayName: String {
        switch self {
        case .remapKey: return "Remap to Key"
        case .modifierCombo: return "Keyboard Shortcut"
        case .mediaControl: return "Media Control"
        case .launchApp: return "Launch Application"
        case .macro: return "Execute Macro"
        case .disable: return "Disable Key"
        }
    }
}

public enum MediaControlAction: String, Codable, CaseIterable {
    case playPause = "playPause"
    case nextTrack = "nextTrack"
    case previousTrack = "previousTrack"
    case volumeUp = "volumeUp"
    case volumeDown = "volumeDown"
    case mute = "mute"
    
    public var displayName: String {
        switch self {
        case .playPause: return "Play / Pause"
        case .nextTrack: return "Next Track"
        case .previousTrack: return "Previous Track"
        case .volumeUp: return "Volume Up"
        case .volumeDown: return "Volume Down"
        case .mute: return "Mute"
        }
    }
}

public struct ModifierFlags: OptionSet, Codable, Hashable {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static let command = ModifierFlags(rawValue: 1 << 0)
    public static let option  = ModifierFlags(rawValue: 1 << 1)
    public static let control = ModifierFlags(rawValue: 1 << 2)
    public static let shift   = ModifierFlags(rawValue: 1 << 3)
}

public struct KeyMapping: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var sourceKeyCode: UInt16
    public var sourceKeyName: String
    public var actionType: KeyActionType
    
    // For remapKey:
    public var targetKeyCode: UInt16?
    public var targetKeyName: String?
    
    // For modifierCombo:
    public var targetModifiers: ModifierFlags
    
    // For mediaControl:
    public var mediaAction: MediaControlAction?
    
    // For launchApp:
    public var appPath: String?
    
    // For macro:
    public var macroId: UUID?
    
    public var isEnabled: Bool
    
    public init(
        id: UUID = UUID(),
        sourceKeyCode: UInt16,
        sourceKeyName: String,
        actionType: KeyActionType,
        targetKeyCode: UInt16? = nil,
        targetKeyName: String? = nil,
        targetModifiers: ModifierFlags = [],
        mediaAction: MediaControlAction? = nil,
        appPath: String? = nil,
        macroId: UUID? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.sourceKeyCode = sourceKeyCode
        self.sourceKeyName = sourceKeyName
        self.actionType = actionType
        self.targetKeyCode = targetKeyCode
        self.targetKeyName = targetKeyName
        self.targetModifiers = targetModifiers
        self.mediaAction = mediaAction
        self.appPath = appPath
        self.macroId = macroId
        self.isEnabled = isEnabled
    }
}
