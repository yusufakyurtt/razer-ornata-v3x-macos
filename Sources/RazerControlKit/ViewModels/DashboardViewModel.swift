import Foundation
import Combine

public final class DashboardViewModel: ObservableObject {
    public let appVM: AppViewModel
    
    public init(appVM: AppViewModel) {
        self.appVM = appVM
    }
    
    public var isConnected: Bool {
        appVM.discovery.isConnected
    }
    
    public var currentDevice: RazerDevice? {
        appVM.discovery.currentDevice
    }
    
    public var activeProfileName: String {
        appVM.profileManager.activeProfile.name
    }
    
    public var isAccessibilityGranted: Bool {
        appVM.permissions.isAccessibilityGranted
    }
    
    public var isInputMonitoringGranted: Bool {
        appVM.permissions.isInputMonitoringGranted
    }
    
    public func requestAccessibility() {
        appVM.permissions.requestAccessibility()
    }
    
    public func requestInputMonitoring() {
        appVM.permissions.requestInputMonitoring()
    }
    
    public func setQuickBrightness(_ value: Double) {
        let clamped = UInt8(max(0, min(255, value * 255.0)))
        var updated = appVM.profileManager.activeProfile
        updated.lighting.brightness = clamped
        appVM.profileManager.updateActiveProfile(updated)
        _ = appVM.lighting.setBrightness(clamped)
    }
}
