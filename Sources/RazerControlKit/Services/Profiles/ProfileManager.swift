import Foundation
import Combine
import AppKit

public protocol ProfileManagerProtocol: ObservableObject {
    var profiles: [Profile] { get }
    var activeProfile: Profile { get }
    func selectProfile(id: UUID)
    func createProfile(name: String) -> Profile
    func duplicateProfile(id: UUID) -> Profile?
    func deleteProfile(id: UUID) -> Bool
    func updateActiveProfile(_ profile: Profile)
    func linkActiveProfile(toAppBundleId bundleId: String?)
}

public final class ProfileManager: ProfileManagerProtocol, ObservableObject {
    @Published public private(set) var profiles: [Profile] = []
    @Published public private(set) var activeProfile: Profile
    
    private let persistence: PersistenceServiceProtocol
    private var workspaceObserver: Any?
    
    public init(persistence: PersistenceServiceProtocol) {
        self.persistence = persistence
        let loaded = persistence.loadProfiles()
        self.profiles = loaded
        
        let settings = persistence.loadSettings()
        if let found = loaded.first(where: { $0.id == settings.activeProfileId }) {
            self.activeProfile = found
        } else {
            self.activeProfile = loaded.first ?? Profile(name: "Default Profile", isDefault: true)
        }
        
        setupWorkspaceObserver()
    }
    
    deinit {
        if let obs = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
    }
    
    public func selectProfile(id: UUID) {
        guard let target = profiles.first(where: { $0.id == id }) else { return }
        self.activeProfile = target
        
        var settings = persistence.loadSettings()
        settings.activeProfileId = id
        _ = persistence.saveSettings(settings)
    }
    
    public func createProfile(name: String) -> Profile {
        let newProfile = Profile(
            name: name,
            isDefault: false,
            lighting: activeProfile.lighting,
            keyMappings: []
        )
        profiles.append(newProfile)
        _ = persistence.saveProfiles(profiles)
        selectProfile(id: newProfile.id)
        return newProfile
    }
    
    public func duplicateProfile(id: UUID) -> Profile? {
        guard let source = profiles.first(where: { $0.id == id }) else { return nil }
        let copy = Profile(
            name: "\(source.name) (Copy)",
            isDefault: false,
            lighting: source.lighting,
            keyMappings: source.keyMappings,
            macros: source.macros,
            associatedAppBundleId: source.associatedAppBundleId
        )
        profiles.append(copy)
        _ = persistence.saveProfiles(profiles)
        selectProfile(id: copy.id)
        return copy
    }
    
    public func deleteProfile(id: UUID) -> Bool {
        guard profiles.count > 1 else { return false } // Keep at least one profile
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return false }
        
        let wasActive = (activeProfile.id == id)
        profiles.remove(at: index)
        _ = persistence.saveProfiles(profiles)
        
        if wasActive {
            self.activeProfile = profiles.first!
            var settings = persistence.loadSettings()
            settings.activeProfileId = activeProfile.id
            _ = persistence.saveSettings(settings)
        }
        return true
    }
    
    public func updateActiveProfile(_ profile: Profile) {
        self.activeProfile = profile
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[idx] = profile
            _ = persistence.saveProfiles(profiles)
        }
    }
    
    public func linkActiveProfile(toAppBundleId bundleId: String?) {
        var updated = activeProfile
        updated.associatedAppBundleId = bundleId
        updateActiveProfile(updated)
    }
    
    private func setupWorkspaceObserver() {
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self = self else { return }
            let settings = self.persistence.loadSettings()
            guard settings.autoProfileSwitching else { return }
            
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleId = app.bundleIdentifier else { return }
            
            if let matched = self.profiles.first(where: { $0.associatedAppBundleId == bundleId }) {
                if matched.id != self.activeProfile.id {
                    self.selectProfile(id: matched.id)
                }
            }
        }
    }
}
