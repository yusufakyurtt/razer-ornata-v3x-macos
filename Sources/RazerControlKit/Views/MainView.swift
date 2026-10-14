import SwiftUI

public struct MainView: View {
    @StateObject private var appVM = AppViewModel()
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 0) {
            SidebarView(appVM: appVM)
            
            Divider()
            
            ZStack {
                Color.razerBackground
                    .ignoresSafeArea()
                
                switch appVM.selectedSection {
                case .dashboard:
                    DashboardView(appVM: appVM)
                case .keyboard:
                    KeyboardVisualizerView(appVM: appVM)
                case .lighting:
                    LightingStudioView(appVM: appVM)
                case .remapping:
                    KeyRemappingView(appVM: appVM)
                case .macros:
                    MacroStudioView(appVM: appVM)
                case .profiles:
                    ProfilesView(appVM: appVM)
                case .settings:
                    SettingsView(appVM: appVM)
                case .diagnostics:
                    DiagnosticsView(appVM: appVM)
                }
            }
        }
        .frame(minWidth: 920, minHeight: 640)
        .preferredColorScheme(colorScheme)
    }
    
    private var colorScheme: ColorScheme? {
        let settings = appVM.persistence.loadSettings()
        switch settings.theme {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
}
