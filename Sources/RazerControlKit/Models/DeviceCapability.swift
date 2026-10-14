import Foundation

public enum CapabilityStatus: String, Codable, CaseIterable {
    case supportedVerified = "supportedVerified"
    case permissionRequired = "permissionRequired"
    case detectedUnverified = "detectedUnverified"
    case unsupported = "unsupported"
    case disconnected = "disconnected"
    case operationFailed = "operationFailed"
    
    public var localizedTitle: String {
        switch self {
        case .supportedVerified:
            return "Supported & Verified"
        case .permissionRequired:
            return "Permission Required"
        case .detectedUnverified:
            return "Detected (Unverified)"
        case .unsupported:
            return "Hardware Limitation"
        case .disconnected:
            return "Disconnected"
        case .operationFailed:
            return "Operation Failed"
        }
    }
}

public struct DeviceCapability: Identifiable, Codable, Hashable {
    public var id: String
    public var name: String
    public var status: CapabilityStatus
    public var discoveryMethod: String
    public var notes: String
    public var requiresPermission: Bool
    
    public init(id: String, name: String, status: CapabilityStatus, discoveryMethod: String, notes: String, requiresPermission: Bool = false) {
        self.id = id
        self.name = name
        self.status = status
        self.discoveryMethod = discoveryMethod
        self.notes = notes
        self.requiresPermission = requiresPermission
    }
}
