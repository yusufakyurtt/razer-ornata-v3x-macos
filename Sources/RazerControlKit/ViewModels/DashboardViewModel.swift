import Foundation
import Combine

public final class DashboardViewModel: ObservableObject {
    public let appVM: AppViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(appVM: AppViewModel) {
        self.appVM = appVM
        
        // Forward changes from appVM, discovery and permissions so SwiftUI views re-render reactively!
        appVM.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        appVM.discovery.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        appVM.permissions.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
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
