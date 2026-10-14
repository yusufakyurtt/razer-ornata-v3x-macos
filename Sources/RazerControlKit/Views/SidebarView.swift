import SwiftUI

public struct SidebarView: View {
    @ObservedObject var appVM: AppViewModel
    
    public init(appVM: AppViewModel) {
        self.appVM = appVM
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header / App Identity
            HStack(spacing: 10) {
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.razerGreen)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("RAZER CONTROL")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    Text("Ornata V3 X")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            
            // Connection Pill
            HStack(spacing: 8) {
                Circle()
                    .fill(appVM.discovery.isConnected ? Color.razerSuccess : Color.razerDanger)
                    .frame(width: 8, height: 8)
                
                Text(appVM.discovery.isConnected ? NSLocalizedString("dash_status_connected", comment: "") : NSLocalizedString("dash_status_disconnected", comment: ""))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(appVM.discovery.isConnected ? .razerSuccess : .razerDanger)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            Divider()
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            // Navigation Links
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(NavigationSection.allCases) { section in
                        Button(action: {
                            appVM.selectedSection = section
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: section.iconName)
                                    .font(.system(size: 14))
                                    .frame(width: 20)
                                    .foregroundColor(appVM.selectedSection == section ? .razerGreen : .secondary)
                                
                                Text(NSLocalizedString(section.rawValue, comment: ""))
                                    .font(.system(size: 13, weight: appVM.selectedSection == section ? .semibold : .regular))
                                    .foregroundColor(appVM.selectedSection == section ? .primary : .secondary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(appVM.selectedSection == section ? Color.razerCardHover : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
            }
            
            Spacer()
            
            // Footer Active Profile Tag
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("dash_active_profile", comment: ""))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                
                Text(appVM.profileManager.activeProfile.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.razerGreen)
                    .lineLimit(1)
            }
            .padding(16)
            .background(Color.razerCard)
        }
        .frame(minWidth: 220, maxWidth: 240)
        .background(Color.razerBackground)
    }
}
