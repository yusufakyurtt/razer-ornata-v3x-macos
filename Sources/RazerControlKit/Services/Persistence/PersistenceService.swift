import Foundation

public protocol PersistenceServiceProtocol: AnyObject {
    func loadProfiles() -> [Profile]
    func saveProfiles(_ profiles: [Profile]) -> Bool
    func loadSettings() -> AppSettings
    func saveSettings(_ settings: AppSettings) -> Bool
    func exportProfile(_ profile: Profile, to url: URL) -> Bool
    func importProfile(from url: URL) -> Result<Profile, Error>
    func resetToDefaults()
}

public final class PersistenceService: PersistenceServiceProtocol {
    private let fileManager = FileManager.default
    private let appSupportDir: URL
    private let profilesFileURL: URL
    private let settingsFileURL: URL
    
    public init() {
        let baseDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = baseDir.appendingPathComponent("RazerControl", isDirectory: true)
        self.appSupportDir = appDir
        self.profilesFileURL = appDir.appendingPathComponent("profiles.json")
        self.settingsFileURL = appDir.appendingPathComponent("settings.json")
        
        createDirectoryIfNeeded()
    }
    
    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: appSupportDir.path) {
            try? fileManager.createDirectory(at: appSupportDir, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    public func loadProfiles() -> [Profile] {
        guard fileManager.fileExists(atPath: profilesFileURL.path),
              let data = try? Data(contentsOf: profilesFileURL),
              let profiles = try? JSONDecoder().decode([Profile].self, from: data) else {
            // Default Profile
            let defaultProfile = Profile(
                name: "Default Profile",
                isDefault: true,
                lighting: LightingConfiguration(
                    effect: .spectrum,
                    primaryColor: .razerGreen,
                    brightness: 224
                )
            )
            _ = saveProfiles([defaultProfile])
            return [defaultProfile]
        }
        return profiles
    }
    
    public func saveProfiles(_ profiles: [Profile]) -> Bool {
        createDirectoryIfNeeded()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(profiles) else { return false }
        do {
            try data.write(to: profilesFileURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }
    
    public func loadSettings() -> AppSettings {
        guard fileManager.fileExists(atPath: settingsFileURL.path),
              let data = try? Data(contentsOf: settingsFileURL),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            let defaultSettings = AppSettings()
            _ = saveSettings(defaultSettings)
            return defaultSettings
        }
        return settings
    }
    
    public func saveSettings(_ settings: AppSettings) -> Bool {
        createDirectoryIfNeeded()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(settings) else { return false }
        do {
            try data.write(to: settingsFileURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }
    
    public func exportProfile(_ profile: Profile, to url: URL) -> Bool {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(profile) else { return false }
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }
    
    public func importProfile(from url: URL) -> Result<Profile, Error> {
        do {
            let data = try Data(contentsOf: url)
            var profile = try JSONDecoder().decode(Profile.self, from: data)
            // Generate a fresh UUID so it doesn't collide with existing profile
            profile.id = UUID()
            profile.isDefault = false
            return .success(profile)
        } catch {
            return .failure(error)
        }
    }
    
    public func resetToDefaults() {
        try? fileManager.removeItem(at: profilesFileURL)
        try? fileManager.removeItem(at: settingsFileURL)
    }
}
