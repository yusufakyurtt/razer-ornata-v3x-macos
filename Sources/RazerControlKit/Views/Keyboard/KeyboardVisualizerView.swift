import SwiftUI

public struct KeyboardVisualizerView: View {
    @StateObject private var viewModel: KeyboardVisualizerViewModel
    
    public init(appVM: AppViewModel) {
        _viewModel = StateObject(wrappedValue: KeyboardVisualizerViewModel(appVM: appVM))
    }
    
    public var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("nav_keyboard", comment: ""))
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Interactive visual layout of the connected Razer Ornata V3 X. Click any key to inspect its mapping.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                // Keyboard Visualization Surface
                VStack(spacing: 6) {
                    ForEach(0..<viewModel.mainRows.count, id: \.self) { rowIdx in
                        HStack(spacing: 6) {
                            ForEach(viewModel.mainRows[rowIdx]) { key in
                                KeyCapView(
                                    key: key,
                                    isSelected: viewModel.selectedKey?.id == key.id,
                                    mapping: viewModel.mappingForKey(key)
                                ) {
                                    viewModel.selectKey(key)
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color.razerCard)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.razerBorder, lineWidth: 1)
                )
                
                // Numpad Area
                VStack(alignment: .leading, spacing: 10) {
                    Text("Numeric Keypad Cluster")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 6) {
                        ForEach(0..<viewModel.numpadRows.count, id: \.self) { rowIdx in
                            HStack(spacing: 6) {
                                ForEach(viewModel.numpadRows[rowIdx]) { key in
                                    KeyCapView(
                                        key: key,
                                        isSelected: viewModel.selectedKey?.id == key.id,
                                        mapping: viewModel.mappingForKey(key)
                                    ) {
                                        viewModel.selectKey(key)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.razerCard)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.razerBorder, lineWidth: 1)
                    )
                }
                
                // Key Inspector Card
                if let key = viewModel.selectedKey {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Key Inspector: \(key.label)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.razerGreen)
                            
                            Spacer()
                            
                            Text("macOS Key Code: \(key.keyCode)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        if let mapping = viewModel.activeMapping {
                            HStack {
                                Text("Current Mapping:")
                                    .fontWeight(.medium)
                                Text(mapping.actionType.displayName)
                                    .foregroundColor(.razerGreen)
                                    .fontWeight(.bold)
                                
                                if let target = mapping.targetKeyName {
                                    Text("➔ \(target)")
                                        .fontWeight(.semibold)
                                }
                                
                                Spacer()
                                
                                Text(mapping.isEnabled ? "Active" : "Disabled")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(mapping.isEnabled ? .razerSuccess : .secondary)
                            }
                        } else {
                            Text("Default system behavior (no custom remapping assigned).")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .razerCard()
                }
            }
            .padding(24)
        }
    }
}

public struct KeyCapView: View {
    public let key: VisualKey
    public let isSelected: Bool
    public let mapping: KeyMapping?
    public let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    public var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                if let sub = key.subLabel {
                    Text(sub)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Text(key.label)
                    .font(.system(size: key.label.count > 3 ? 9 : 11, weight: .semibold))
                    .foregroundColor(isSelected ? .black : (mapping != nil ? .razerGreen : .primary))
            }
            .frame(width: CGFloat(key.width * 42.0), height: CGFloat(key.height * 42.0))
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? Color.razerGreen : (isHovered ? Color.razerCardHover : Color(red: 0.16, green: 0.16, blue: 0.16)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? Color.razerGreen : (mapping != nil ? Color.razerGreen.opacity(0.8) : Color.razerBorder), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
