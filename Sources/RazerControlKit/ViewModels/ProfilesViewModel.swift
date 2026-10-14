import Foundation
import Combine
import AppKit

public final class ProfilesViewModel: ObservableObject {
    public let appVM: AppViewModel
    
    @Published public var profiles: [Profile] = []
    @Published public var activeProfile: Profile
    @Published public var newProfileName: String = ""
    @Published public var showNewProfileDialog: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(appVM: AppViewModel) {
        self.appVM = appVM
        self.profiles = appVM.profileManager.profiles
        self.activeProfile = appVM.profileManager.activeProfile
        
        appVM.profileManager.$profiles
            .assign(to: \.profiles, on: self)
            .store(in: &cancellables)
            
        appVM.profileManager.$activeProfile
            .assign(to: \.activeProfile, on: self)
            .store(in: &cancellables)
    }
    
    public func selectProfile(_ profile: Profile) {
        appVM.profileManager.selectProfile(id: profile.id)
    }
    
    public func createProfile() {
        guard !newProfileName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        _ = appVM.profileManager.createProfile(name: newProfileName)
        newProfileName = ""
        showNewProfileDialog = false
    }
    
    public func duplicateProfile(_ profile: Profile) {
        _ = appVM.profileManager.duplicateProfile(id: profile.id)
    }
    
    public func deleteProfile(_ profile: Profile) {
        _ = appVM.profileManager.deleteProfile(id: profile.id)
    }
    
    public func exportProfile(_ profile: Profile) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(profile.name).razerprofile"
        if panel.runModal() == .OK, let url = panel.url {
            _ = appVM.persistence.exportProfile(profile, to: url)
        }
    }
    
    public func importProfile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            let res = appVM.persistence.importProfile(from: url)
            if case .success(let imported) = res {
                var current = appVM.profileManager.profiles
                current.append(imported)
                _ = appVM.persistence.saveProfiles(current)
                appVM.profileManager.selectProfile(id: imported.id)
            }
        }
    }
}
