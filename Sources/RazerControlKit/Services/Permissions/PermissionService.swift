import Foundation
import AppKit
import ApplicationServices
import CoreGraphics

public protocol PermissionServiceProtocol: ObservableObject {
    var isAccessibilityGranted: Bool { get }
    var isInputMonitoringGranted: Bool { get }
    func checkPermissions()
    func requestAccessibility()
    func requestInputMonitoring()
    func openAccessibilitySettings()
    func openInputMonitoringSettings()
}

public final class PermissionService: PermissionServiceProtocol, ObservableObject {
    @Published public private(set) var isAccessibilityGranted: Bool = false
    @Published public private(set) var isInputMonitoringGranted: Bool = false
    
    private var timer: Timer?
    private var activeObserver: NSObjectProtocol?
    
    public init() {
        checkPermissions()
        
        // Refresh permissions whenever user returns to the app from System Settings
        activeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkPermissions()
        }
        
        // Periodically refresh permissions in common modes so it never freezes
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkPermissions()
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }
    
    deinit {
        timer?.invalidate()
        if let obs = activeObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
    
    public func checkPermissions() {
        // Accessibility Check
        let trusted = AXIsProcessTrusted()
        
        // Input Monitoring Check (macOS 10.15+)
        let inputMonitoring: Bool
        if #available(macOS 10.15, *) {
            inputMonitoring = CGPreflightListenEventAccess()
        } else {
            inputMonitoring = true
        }
        
        DispatchQueue.main.async {
            if self.isAccessibilityGranted != trusted {
                self.isAccessibilityGranted = trusted
            }
            if self.isInputMonitoringGranted != inputMonitoring {
                self.isInputMonitoringGranted = inputMonitoring
            }
        }
    }
    
    public func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        checkPermissions()
    }
    
    public func requestInputMonitoring() {
        if #available(macOS 10.15, *) {
            _ = CGRequestListenEventAccess()
        }
        checkPermissions()
    }
    
    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    public func openInputMonitoringSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }
}
