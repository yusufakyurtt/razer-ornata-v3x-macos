import Foundation
import SwiftUI
import Combine

public enum NavigationSection: String, CaseIterable, Identifiable {
    case dashboard = "nav_dashboard"
    case keyboard = "nav_keyboard"
    case lighting = "nav_lighting"
    case remapping = "nav_remapping"
    case macros = "nav_macros"
    case profiles = "nav_profiles"
    case settings = "nav_settings"
    case diagnostics = "nav_diagnostics"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .dashboard: return "gauge.medium"
        case .keyboard: return "keyboard"
        case .lighting: return "lightbulb.fill"
        case .remapping: return "arrow.triangle.2.circlepath"
        case .macros: return "command"
        case .profiles: return "folder.fill"
        case .settings: return "gearshape.fill"
        case .diagnostics: return "waveform.path.ecg"
        }
    }
}

public final class AppViewModel: ObservableObject {
    @Published public var selectedSection: NavigationSection = .dashboard
    
    // Services
    public let persistence: PersistenceService
    public let discovery: DeviceDiscoveryService
    public let lighting: LightingService
    public let remapping: KeyRemappingEngine
    public let macroEngine: MacroEngine
    public let profileManager: ProfileManager
    public let permissions: PermissionService
    public let diagnostics: DiagnosticService
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        self.persistence = PersistenceService()
        self.discovery = DeviceDiscoveryService()
        self.lighting = LightingService(session: discovery.session)
        self.remapping = KeyRemappingEngine()
        self.macroEngine = MacroEngine()
        self.profileManager = ProfileManager(persistence: persistence)
        self.permissions = PermissionService()
        self.diagnostics = DiagnosticService.shared
        
        setupBindings()
        
        // Start device discovery and remapping engine
        discovery.startDiscovery()
        _ = remapping.start()
    }
    
    private func setupBindings() {
        // Forward changes from child services so views reactively update
        discovery.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
            
        permissions.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
            
        profileManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
            
        // Sync active profile key mappings into remapping engine
        profileManager.$activeProfile
            .sink { [weak self] profile in
                guard let self = self else { return }
                self.remapping.updateMappings(profile.keyMappings)
                // If keyboard is connected, apply lighting configuration
                if self.discovery.isConnected {
                    _ = self.lighting.applyConfiguration(profile.lighting)
                }
            }
            .store(in: &cancellables)
            
        // When device connects, apply active profile lighting
        discovery.$isConnected
            .dropFirst()
            .sink { [weak self] connected in
                guard let self = self, connected else { return }
                self.diagnostics.log(category: "Hardware", level: .success, message: "Razer Ornata V3 X connected", details: "Serial: \(self.discovery.currentDevice?.serialNumber ?? "N/A")")
                _ = self.lighting.applyConfiguration(self.profileManager.activeProfile.lighting)
            }
            .store(in: &cancellables)
            
        // Macro trigger notification from KeyRemappingEngine
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RazerTriggerMacro"),
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self = self,
                  let macroId = note.object as? UUID,
                  let macro = self.profileManager.activeProfile.macros.first(where: { $0.id == macroId }) else { return }
            self.macroEngine.play(macro: macro)
        }
    }
}
