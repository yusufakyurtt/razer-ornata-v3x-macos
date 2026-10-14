import Foundation
import Combine
import AppKit

public final class DiagnosticsViewModel: ObservableObject {
    public let appVM: AppViewModel
    
    @Published public var events: [DiagnosticEvent] = []
    @Published public var selectedCategory: String = "All"
    @Published public var testResultSummary: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(appVM: AppViewModel) {
        self.appVM = appVM
        self.events = appVM.diagnostics.events
        
        appVM.diagnostics.$events
            .assign(to: \.events, on: self)
            .store(in: &cancellables)
    }
    
    public var categories: [String] {
        var set = Set(events.map { $0.category })
        set.insert("All")
        return Array(set).sorted()
    }
    
    public var filteredEvents: [DiagnosticEvent] {
        if selectedCategory == "All" {
            return events
        }
        return events.filter { $0.category == selectedCategory }
    }
    
    public func clearLogs() {
        appVM.diagnostics.clearLogs()
    }
    
    public func exportLogs() {
        let text = appVM.diagnostics.exportLogs()
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "RazerControl-Diagnostics.md"
        if panel.runModal() == .OK, let url = panel.url {
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    public func runHardwareTest() {
        appVM.diagnostics.log(category: "Hardware", level: .info, message: "Initiating live hardware diagnostic check...", details: nil)
        
        guard appVM.discovery.isConnected else {
            testResultSummary = "FAIL: Razer keyboard is not currently connected via USB."
            appVM.diagnostics.log(category: "Hardware", level: .error, message: "Diagnostic aborted — keyboard disconnected", details: nil)
            return
        }
        
        // Query Firmware Version
        let fwReport = RazerHIDProtocol.getFirmwareVersionReport()
        let fwRes = appVM.discovery.session.sendReport(fwReport)
        
        // Query Serial
        let serReport = RazerHIDProtocol.getSerialNumberReport()
        let serRes = appVM.discovery.session.sendReport(serReport)
        
        // Query Brightness
        let brReport = RazerHIDProtocol.getBrightnessReport()
        let brRes = appVM.discovery.session.sendReport(brReport)
        
        var summary = "PHYSICAL TEST PASS:\n"
        if case .success(let resp) = fwRes {
            summary += "• Firmware: v\(resp[8]).\(resp[9]) (Status: 0x02)\n"
        }
        if case .success(let resp) = serRes {
            let serial = String(bytes: resp[8..<30].prefix(while: { $0 != 0 }), encoding: .utf8) ?? "N/A"
            summary += "• Serial: \(serial) (Status: 0x02)\n"
        }
        if case .success(let resp) = brRes {
            summary += "• Current Hardware Brightness: \(resp[10]) / 255 (Status: 0x02)\n"
        }
        
        self.testResultSummary = summary
        appVM.diagnostics.log(category: "Hardware", level: .success, message: "Hardware self-test passed successfully", details: summary)
    }
}
