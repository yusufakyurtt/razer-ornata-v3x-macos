import Foundation
import Combine

public protocol DiagnosticServiceProtocol: ObservableObject {
    var events: [DiagnosticEvent] { get }
    func log(category: String, level: DiagnosticLevel, message: String, details: String?)
    func clearLogs()
    func exportLogs() -> String
}

public final class DiagnosticService: DiagnosticServiceProtocol, ObservableObject {
    @Published public private(set) var events: [DiagnosticEvent] = []
    private let maxEvents = 500
    private let lock = NSLock()
    
    public static let shared = DiagnosticService()
    
    public init() {
        log(category: "System", level: .info, message: "Razer Control Diagnostic Engine initialized", details: nil)
    }
    
    public func log(category: String, level: DiagnosticLevel, message: String, details: String? = nil) {
        let event = DiagnosticEvent(
            category: category,
            level: level,
            message: message,
            details: details
        )
        
        lock.lock()
        defer { lock.unlock() }
        
        DispatchQueue.main.async {
            self.events.insert(event, at: 0)
            if self.events.count > self.maxEvents {
                self.events.removeLast()
            }
        }
    }
    
    public func clearLogs() {
        lock.lock()
        defer { lock.unlock() }
        DispatchQueue.main.async {
            self.events.removeAll()
        }
    }
    
    public func exportLogs() -> String {
        lock.lock()
        defer { lock.unlock() }
        
        let formatter = ISO8601DateFormatter()
        var output = "# Razer Control Diagnostic Log Export\n"
        output += "Generated: \(formatter.string(from: Date()))\n\n"
        output += "| Timestamp | Level | Category | Message | Details |\n"
        output += "|---|---|---|---|---|\n"
        
        for ev in events {
            let ts = formatter.string(from: ev.timestamp)
            let det = ev.details?.replacingOccurrences(of: "\n", with: " ") ?? "-"
            output += "| \(ts) | \(ev.level.rawValue) | \(ev.category) | \(ev.message) | \(det) |\n"
        }
        return output
    }
}
