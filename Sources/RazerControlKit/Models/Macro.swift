import Foundation

public enum MacroActionType: String, Codable, CaseIterable {
    case keyDown = "keyDown"
    case keyUp = "keyUp"
    case delay = "delay"
}

public struct MacroEvent: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var type: MacroActionType
    public var keyCode: UInt16?
    public var keyName: String?
    public var delayMs: UInt32? // Used when type == .delay
    
    public init(id: UUID = UUID(), type: MacroActionType, keyCode: UInt16? = nil, keyName: String? = nil, delayMs: UInt32? = nil) {
        self.id = id
        self.type = type
        self.keyCode = keyCode
        self.keyName = keyName
        self.delayMs = delayMs
    }
}

public struct Macro: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var events: [MacroEvent]
    public var repeatCount: UInt32
    
    public init(id: UUID = UUID(), name: String, events: [MacroEvent] = [], repeatCount: UInt32 = 1) {
        self.id = id
        self.name = name
        self.events = events
        self.repeatCount = repeatCount
    }
}
