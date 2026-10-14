import SwiftUI

public struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var showResetConfirm: Bool = false
    
    public init(appVM: AppViewModel) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(appVM: appVM))
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("settings_title", comment: ""))
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Configure application behavior, language, and system integrations.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                // Appearance Card
                VStack(alignment: .leading, spacing: 14) {
                    Text(NSLocalizedString("settings_appearance", comment: ""))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.razerGreen)
                    
                    HStack {
                        Text(NSLocalizedString("settings_theme", comment: ""))
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Picker("", selection: $viewModel.theme) {
                            ForEach(AppTheme.allCases, id: \.self) { thm in
                                Text(thm.displayName).tag(thm)
                            }
                        }
                        .frame(width: 140)
                        .onChange(of: viewModel.theme) { _ in
                            viewModel.updateSettings()
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text(NSLocalizedString("settings_language", comment: ""))
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Picker("", selection: $viewModel.language) {
                            ForEach(AppLanguage.allCases, id: \.self) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .frame(width: 140)
                        .onChange(of: viewModel.language) { _ in
                            viewModel.updateSettings()
                        }
                    }
                }
                .razerCard()
                
                // System & Background Behavior
                VStack(alignment: .leading, spacing: 14) {
                    Text("System & Background Behavior")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Toggle(NSLocalizedString("settings_launch_login", comment: ""), isOn: $viewModel.launchAtLogin)
                        .onChange(of: viewModel.launchAtLogin) { _ in viewModel.updateSettings() }
                    
                    Toggle(NSLocalizedString("settings_start_minimized", comment: ""), isOn: $viewModel.startMinimized)
                        .onChange(of: viewModel.startMinimized) { _ in viewModel.updateSettings() }
                    
                    Toggle(NSLocalizedString("settings_auto_profile", comment: ""), isOn: $viewModel.autoProfileSwitching)
                        .onChange(of: viewModel.autoProfileSwitching) { _ in viewModel.updateSettings() }
                }
                .razerCard()
                
                // Factory Reset
                VStack(alignment: .leading, spacing: 12) {
                    Text("Configuration Management")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        showResetConfirm = true
                    }) {
                        Text(NSLocalizedString("settings_reset_btn", comment: ""))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.razerDanger)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.razerDanger.opacity(0.12))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Are you sure you want to reset all profiles and settings?", isPresented: $showResetConfirm) {
                        Button("Reset All to Defaults", role: .destructive) {
                            viewModel.resetAllToDefaults()
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
                .razerCard()
                
                // About Card
                VStack(alignment: .leading, spacing: 10) {
                    Text(NSLocalizedString("settings_about", comment: ""))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Razer Control — Native macOS Alternative to Razer Synapse")
                        .font(.system(size: 13, weight: .semibold))
                    
                    Text(NSLocalizedString("settings_native_notice", comment: ""))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 6) {
                        GridRow {
                            Text("Application Version:")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("1.0.0 (Build 1)")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                        }
                        GridRow {
                            Text("Target Architecture:")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("Intel (x86_64) / Native macOS")
                                .font(.system(size: 12, weight: .medium))
                        }
                        GridRow {
                            Text("Bundle Identifier:")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("app.momentoid.razercontrol")
                                .font(.system(size: 12, design: .monospaced))
                        }
                        GridRow {
                            Text("Hardware Target:")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("Razer Ornata V3 X (RZ03-0447)")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                }
                .razerCard()
            }
            .padding(24)
        }
    }
}
