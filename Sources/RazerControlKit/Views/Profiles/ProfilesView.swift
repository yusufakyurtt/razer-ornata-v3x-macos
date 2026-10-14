import SwiftUI

public struct ProfilesView: View {
    @StateObject private var viewModel: ProfilesViewModel
    @State private var appBundleIdText: String = ""
    
    public init(appVM: AppViewModel) {
        _viewModel = StateObject(wrappedValue: ProfilesViewModel(appVM: appVM))
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("profiles_title", comment: ""))
                            .font(.system(size: 24, weight: .bold))
                        
                        Text(NSLocalizedString("profiles_desc", comment: ""))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.showNewProfileDialog = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text(NSLocalizedString("profiles_new_btn", comment: ""))
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.razerGreen)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                
                // Profile List Card
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.profiles) { profile in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 8) {
                                    Text(profile.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(profile.id == viewModel.activeProfile.id ? .razerGreen : .primary)
                                    
                                    if profile.id == viewModel.activeProfile.id {
                                        Text("ACTIVE")
                                            .font(.system(size: 9, weight: .black))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.razerGreen.opacity(0.2))
                                            .foregroundColor(.razerGreen)
                                            .cornerRadius(4)
                                    }
                                }
                                
                                Text("Mappings: \(profile.keyMappings.count) | Macros: \(profile.macros.count) | Effect: \(profile.lighting.effect.displayName)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if profile.id != viewModel.activeProfile.id {
                                Button("Select") {
                                    viewModel.selectProfile(profile)
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.razerCardHover)
                                .cornerRadius(4)
                            }
                            
                            Button(action: {
                                viewModel.duplicateProfile(profile)
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Duplicate Profile")
                            
                            Button(action: {
                                viewModel.exportProfile(profile)
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Export Profile JSON")
                            
                            if viewModel.profiles.count > 1 {
                                Button(action: {
                                    viewModel.deleteProfile(profile)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.razerDanger)
                                }
                                .buttonStyle(.plain)
                                .help("Delete Profile")
                            }
                        }
                        Divider()
                    }
                }
                .razerCard()
                
                // Import & Application Association Card
                VStack(alignment: .leading, spacing: 14) {
                    Text("Profile Tools & Automation")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack {
                        Button(action: {
                            viewModel.importProfile()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text(NSLocalizedString("profiles_import_btn", comment: ""))
                            }
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.razerCardHover)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString("profiles_link_app", comment: ""))
                            .font(.system(size: 13, weight: .medium))
                        
                        Text("Associate this profile with an application bundle ID (e.g., com.blizzard.worldofwarcraft) for automatic switching.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("com.example.app", text: $appBundleIdText)
                                .textFieldStyle(.roundedBorder)
                                .onAppear {
                                    appBundleIdText = viewModel.activeProfile.associatedAppBundleId ?? ""
                                }
                                .onChange(of: viewModel.activeProfile) { newProfile in
                                    appBundleIdText = newProfile.associatedAppBundleId ?? ""
                                }
                            
                            Button("Save Association") {
                                viewModel.appVM.profileManager.linkActiveProfile(toAppBundleId: appBundleIdText.isEmpty ? nil : appBundleIdText)
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.razerGreen)
                            .foregroundColor(.black)
                            .cornerRadius(6)
                        }
                    }
                }
                .razerCard()
            }
            .padding(24)
        }
        .sheet(isPresented: $viewModel.showNewProfileDialog) {
            VStack(alignment: .leading, spacing: 16) {
                Text(NSLocalizedString("profiles_new_btn", comment: ""))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.razerGreen)
                
                TextField(NSLocalizedString("profiles_name_placeholder", comment: ""), text: $viewModel.newProfileName)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    Spacer()
                    Button("Cancel") {
                        viewModel.showNewProfileDialog = false
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    
                    Button("Create") {
                        viewModel.createProfile()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.razerGreen)
                    .cornerRadius(6)
                }
            }
            .padding(20)
            .frame(width: 320)
            .background(Color.razerBackground)
        }
    }
}
