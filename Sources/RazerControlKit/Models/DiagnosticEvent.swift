import Foundation

public enum DiagnosticLevel: String, Codable, CaseIterable {
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
    case success = "SUCCESS"
}

public struct DiagnosticEvent: Identifiable, Codable, Hashable {
    public var id: UUID
    public var timestamp: Date
    public var category: String
    public var level: DiagnosticLevel
    public var message: String
    public var details: String?
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), category: String, level: DiagnosticLevel, message: String, details: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.level = level
        self.message = message
        self.details = details
    }
}
