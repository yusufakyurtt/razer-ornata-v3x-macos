import Foundation
import Combine

public final class KeyRemappingViewModel: ObservableObject {
    public let appVM: AppViewModel
    
    @Published public var mappings: [KeyMapping] = []
    @Published public var showAddModal: Bool = false
    @Published public var editingMapping: KeyMapping?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(appVM: AppViewModel) {
        self.appVM = appVM
        self.mappings = appVM.profileManager.activeProfile.keyMappings
        
        appVM.profileManager.$activeProfile
            .sink { [weak self] profile in
                self?.mappings = profile.keyMappings
            }
            .store(in: &cancellables)
    }
    
    public func saveMapping(_ mapping: KeyMapping) {
        var profile = appVM.profileManager.activeProfile
        if let idx = profile.keyMappings.firstIndex(where: { $0.id == mapping.id || $0.sourceKeyCode == mapping.sourceKeyCode }) {
            profile.keyMappings[idx] = mapping
        } else {
            profile.keyMappings.append(mapping)
        }
        appVM.profileManager.updateActiveProfile(profile)
        appVM.diagnostics.log(category: "Remap", level: .info, message: "Updated mapping for key '\(mapping.sourceKeyName)' -> \(mapping.actionType.displayName)", details: nil)
    }
    
    public func toggleMapping(_ mapping: KeyMapping) {
        var updated = mapping
        updated.isEnabled.toggle()
        saveMapping(updated)
    }
    
    public func deleteMapping(id: UUID) {
        var profile = appVM.profileManager.activeProfile
        profile.keyMappings.removeAll(where: { $0.id == id })
        appVM.profileManager.updateActiveProfile(profile)
        appVM.diagnostics.log(category: "Remap", level: .info, message: "Deleted key mapping", details: id.uuidString)
    }
}
