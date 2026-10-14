import Foundation
import Combine
import SwiftUI

public final class SettingsViewModel: ObservableObject {
    public let appVM: AppViewModel
    
    @Published public var theme: AppTheme
    @Published public var language: AppLanguage
    @Published public var launchAtLogin: Bool
    @Published public var startMinimized: Bool
    @Published public var autoProfileSwitching: Bool
    
    public init(appVM: AppViewModel) {
        self.appVM = appVM
        let settings = appVM.persistence.loadSettings()
        self.theme = settings.theme
        self.language = settings.language
        self.launchAtLogin = settings.launchAtLogin
        self.startMinimized = settings.startMinimized
        self.autoProfileSwitching = settings.autoProfileSwitching
    }
    
    public func updateSettings() {
        var settings = appVM.persistence.loadSettings()
        settings.theme = theme
        settings.language = language
        settings.launchAtLogin = launchAtLogin
        settings.startMinimized = startMinimized
        settings.autoProfileSwitching = autoProfileSwitching
        _ = appVM.persistence.saveSettings(settings)
    }
    
    public func resetAllToDefaults() {
        appVM.persistence.resetToDefaults()
        let settings = appVM.persistence.loadSettings()
        self.theme = settings.theme
        self.language = settings.language
        self.launchAtLogin = settings.launchAtLogin
        self.startMinimized = settings.startMinimized
        self.autoProfileSwitching = settings.autoProfileSwitching
    }
}
