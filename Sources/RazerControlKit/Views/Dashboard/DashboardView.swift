import SwiftUI

public struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @State private var quickBrightness: Double = 0.88
    
    public init(appVM: AppViewModel) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(appVM: appVM))
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("dash_title", comment: ""))
                            .font(.system(size: 24, weight: .bold))
                        
                        Text(viewModel.isConnected ? NSLocalizedString("dash_status_connected", comment: "") : NSLocalizedString("dash_status_disconnected", comment: ""))
                            .font(.system(size: 13))
                            .foregroundColor(viewModel.isConnected ? .razerSuccess : .razerDanger)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.appVM.discovery.refreshDeviceState()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Device")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.razerCardHover)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                
                // Device Hardware Info Card
                VStack(alignment: .leading, spacing: 14) {
                    Text(NSLocalizedString("dash_device_info", comment: ""))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.razerGreen)
                    
                    if viewModel.isConnected, let dev = viewModel.currentDevice {
                        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                            GridRow {
                                Text(NSLocalizedString("dash_model", comment: "") + ":")
                                    .foregroundColor(.secondary)
                                Text("\(dev.name) (\(dev.modelFamily))")
                                    .fontWeight(.medium)
                            }
                            GridRow {
                                Text(NSLocalizedString("dash_serial", comment: "") + ":")
                                    .foregroundColor(.secondary)
                                Text(dev.serialNumber.isEmpty ? "Reading..." : dev.serialNumber)
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.semibold)
                            }
                            GridRow {
                                Text(NSLocalizedString("dash_firmware", comment: "") + ":")
                                    .foregroundColor(.secondary)
                                Text(dev.firmwareVersion.isEmpty ? "Reading..." : dev.firmwareVersion)
                                    .fontWeight(.medium)
                            }
                            GridRow {
                                Text(NSLocalizedString("dash_layout", comment: "") + ":")
                                    .foregroundColor(.secondary)
                                Text(dev.physicalLayout)
                                    .fontWeight(.medium)
                            }
                            GridRow {
                                Text("USB Identifiers:")
                                    .foregroundColor(.secondary)
                                Text("VID: 0x\(String(format: "%04X", dev.vendorId)) | PID: 0x\(String(format: "%04X", dev.productId)) | Location: 0x\(String(format: "%08X", dev.locationId))")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("dash_status_disconnected", comment: ""))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.razerDanger)
                            
                            Text(NSLocalizedString("dash_status_reconnect_desc", comment: ""))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .razerCard()
                
                // Quick Lighting Adjustment Card
                if viewModel.isConnected {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(NSLocalizedString("dash_quick_lighting", comment: ""))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.razerGreen)
                        
                        HStack(spacing: 16) {
                            Image(systemName: "sun.min.fill")
                                .foregroundColor(.secondary)
                            
                            Slider(value: $quickBrightness, in: 0...1.0) { _ in
                                viewModel.setQuickBrightness(quickBrightness)
                            }
                            .accentColor(.razerGreen)
                            
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(.razerGreen)
                            
                            Text("\(Int(quickBrightness * 100))%")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .frame(width: 45, alignment: .trailing)
                        }
                    }
                    .razerCard()
                }
                
                // Permissions Card
                VStack(alignment: .leading, spacing: 14) {
                    Text(NSLocalizedString("dash_permissions_title", comment: ""))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(NSLocalizedString("dash_permission_acc", comment: ""))
                                .font(.system(size: 13, weight: .medium))
                            Text("Required for global key remapping and macro execution.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if viewModel.isAccessibilityGranted {
                            Label(NSLocalizedString("dash_permission_granted", comment: ""), systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.razerSuccess)
                        } else {
                            Button(action: {
                                viewModel.requestAccessibility()
                            }) {
                                Text(NSLocalizedString("dash_permission_grant_btn", comment: ""))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.razerGreen)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(NSLocalizedString("dash_permission_input", comment: ""))
                                .font(.system(size: 13, weight: .medium))
                            Text("Required to observe keyboard events when app is in the background.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if viewModel.isInputMonitoringGranted {
                            Label(NSLocalizedString("dash_permission_granted", comment: ""), systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.razerSuccess)
                        } else {
                            Button(action: {
                                viewModel.requestInputMonitoring()
                            }) {
                                Text(NSLocalizedString("dash_permission_grant_btn", comment: ""))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.razerGreen)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .razerCard()
                
                // Verified Capabilities Card
                VStack(alignment: .leading, spacing: 14) {
                    Text(NSLocalizedString("dash_hardware_caps", comment: ""))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if let dev = viewModel.currentDevice {
                        VStack(spacing: 8) {
                            ForEach(dev.capabilities) { cap in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(cap.name)
                                            .font(.system(size: 13, weight: .medium))
                                        Text(cap.notes)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(cap.status.localizedTitle)
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            cap.status == .supportedVerified ? Color.razerSuccess.opacity(0.15) :
                                            cap.status == .permissionRequired ? Color.razerWarning.opacity(0.15) :
                                            Color.secondary.opacity(0.15)
                                        )
                                        .foregroundColor(
                                            cap.status == .supportedVerified ? .razerSuccess :
                                            cap.status == .permissionRequired ? .razerWarning :
                                            .secondary
                                        )
                                        .cornerRadius(4)
                                }
                                Divider()
                            }
                        }
                    } else {
                        Text("Capabilities will display once keyboard is connected.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .razerCard()
            }
            .padding(24)
        }
    }
}
