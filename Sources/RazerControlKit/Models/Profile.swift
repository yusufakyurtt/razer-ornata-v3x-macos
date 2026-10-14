import Foundation

public struct Profile: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var isDefault: Bool
    public var lighting: LightingConfiguration
    public var keyMappings: [KeyMapping]
    public var macros: [Macro]
    public var associatedAppBundleId: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        isDefault: Bool = false,
        lighting: LightingConfiguration = LightingConfiguration(),
        keyMappings: [KeyMapping] = [],
        macros: [Macro] = [],
        associatedAppBundleId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
        self.lighting = lighting
        self.keyMappings = keyMappings
        self.macros = macros
        self.associatedAppBundleId = associatedAppBundleId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
