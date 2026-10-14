import Foundation

public enum AppTheme: String, Codable, CaseIterable {
    case dark = "dark"
    case light = "light"
    case system = "system"
    
    public var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        case .system: return "System"
        }
    }
}

public enum AppLanguage: String, Codable, CaseIterable {
    case english = "en"
    case turkish = "tr"
    
    public var displayName: String {
        switch self {
        case .english: return "English"
        case .turkish: return "Türkçe"
        }
    }
}

public struct AppSettings: Codable, Equatable {
    public var theme: AppTheme
    public var language: AppLanguage
    public var launchAtLogin: Bool
    public var startMinimized: Bool
    public var autoProfileSwitching: Bool
    public var activeProfileId: UUID
    
    public init(
        theme: AppTheme = .dark,
        language: AppLanguage = .english,
        launchAtLogin: Bool = false,
        startMinimized: Bool = false,
        autoProfileSwitching: Bool = false,
        activeProfileId: UUID = UUID()
    ) {
        self.theme = theme
        self.language = language
        self.launchAtLogin = launchAtLogin
        self.startMinimized = startMinimized
        self.autoProfileSwitching = autoProfileSwitching
        self.activeProfileId = activeProfileId
    }
}
