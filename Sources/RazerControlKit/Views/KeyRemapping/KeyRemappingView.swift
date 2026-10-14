import SwiftUI

public struct KeyRemappingView: View {
    @StateObject private var viewModel: KeyRemappingViewModel
    
    public init(appVM: AppViewModel) {
        _viewModel = StateObject(wrappedValue: KeyRemappingViewModel(appVM: appVM))
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("remap_title", comment: ""))
                            .font(.system(size: 24, weight: .bold))
                        
                        Text(NSLocalizedString("remap_desc", comment: ""))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.showAddModal = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text(NSLocalizedString("remap_add_btn", comment: ""))
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
                
                // Mappings List Card
                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.mappings.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "keyboard.badge.ellipsis")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary)
                            Text(NSLocalizedString("remap_no_mappings", comment: ""))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    } else {
                        ForEach(viewModel.mappings) { mapping in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mapping.sourceKeyName)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.razerGreen)
                                    
                                    HStack(spacing: 6) {
                                        Text(mapping.actionType.displayName)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                        
                                        if let target = mapping.targetKeyName {
                                            Text("➔ \(target)")
                                                .font(.system(size: 12, weight: .semibold))
                                        } else if let media = mapping.mediaAction {
                                            Text("➔ \(media.displayName)")
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { mapping.isEnabled },
                                    set: { _ in viewModel.toggleMapping(mapping) }
                                ))
                                .labelsHidden()
                                .toggleStyle(.switch)
                                
                                Button(action: {
                                    viewModel.deleteMapping(id: mapping.id)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.razerDanger)
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 8)
                            }
                            Divider()
                        }
                    }
                }
                .razerCard()
            }
            .padding(24)
        }
        .sheet(isPresented: $viewModel.showAddModal) {
            AddMappingSheet(onSave: { newMapping in
                viewModel.saveMapping(newMapping)
                viewModel.showAddModal = false
            }, onCancel: {
                viewModel.showAddModal = false
            })
        }
    }
}

public struct AddMappingSheet: View {
    public let onSave: (KeyMapping) -> Void
    public let onCancel: () -> Void
    
    @State private var sourceKeyName: String = "F1"
    @State private var sourceKeyCode: UInt16 = 122
    @State private var actionType: KeyActionType = .remapKey
    @State private var targetKeyName: String = "A"
    @State private var targetKeyCode: UInt16 = 0
    @State private var selectedMediaAction: MediaControlAction = .playPause
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add Key Mapping")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.razerGreen)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(NSLocalizedString("remap_source_key", comment: ""))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $sourceKeyCode) {
                    Text("F1 (Key 122)").tag(UInt16(122))
                    Text("F2 (Key 120)").tag(UInt16(120))
                    Text("F3 (Key 99)").tag(UInt16(99))
                    Text("F4 (Key 118)").tag(UInt16(118))
                    Text("F9 (Key 101)").tag(UInt16(101))
                    Text("F10 (Key 109)").tag(UInt16(109))
                    Text("Caps Lock (Key 57)").tag(UInt16(57))
                    Text("Pause / Break (Key 113)").tag(UInt16(113))
                }
                .pickerStyle(.menu)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(NSLocalizedString("remap_action_type", comment: ""))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $actionType) {
                    ForEach(KeyActionType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            if actionType == .remapKey {
                VStack(alignment: .leading, spacing: 6) {
                    Text(NSLocalizedString("remap_target_key", comment: ""))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $targetKeyCode) {
                        Text("A (Key 0)").tag(UInt16(0))
                        Text("S (Key 1)").tag(UInt16(1))
                        Text("D (Key 2)").tag(UInt16(2))
                        Text("W (Key 13)").tag(UInt16(13))
                        Text("Space (Key 49)").tag(UInt16(49))
                        Text("Return / Enter (Key 36)").tag(UInt16(36))
                        Text("Escape (Key 53)").tag(UInt16(53))
                    }
                    .pickerStyle(.menu)
                }
            } else if actionType == .mediaControl {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Media Action")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $selectedMediaAction) {
                        ForEach(MediaControlAction.allCases, id: \.self) { act in
                            Text(act.displayName).tag(act)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            HStack(spacing: 12) {
                Spacer()
                Button(NSLocalizedString("remap_cancel", comment: "")) {
                    onCancel()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.razerCardHover)
                .cornerRadius(6)
                
                Button(NSLocalizedString("remap_save", comment: "")) {
                    let mapping = KeyMapping(
                        sourceKeyCode: sourceKeyCode,
                        sourceKeyName: "Key \(sourceKeyCode)",
                        actionType: actionType,
                        targetKeyCode: (actionType == .remapKey) ? targetKeyCode : nil,
                        targetKeyName: (actionType == .remapKey) ? "Key \(targetKeyCode)" : nil,
                        mediaAction: (actionType == .mediaControl) ? selectedMediaAction : nil
                    )
                    onSave(mapping)
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.razerGreen)
                .cornerRadius(6)
            }
            .padding(.top, 10)
        }
        .padding(24)
        .frame(minWidth: 420)
        .background(Color.razerBackground)
    }
}
