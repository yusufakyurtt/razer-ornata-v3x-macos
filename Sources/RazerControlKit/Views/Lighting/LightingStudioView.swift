import SwiftUI

public struct LightingStudioView: View {
    @StateObject private var viewModel: LightingStudioViewModel
    
    public init(appVM: AppViewModel) {
        _viewModel = StateObject(wrappedValue: LightingStudioViewModel(appVM: appVM))
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("lighting_title", comment: ""))
                        .font(.system(size: 24, weight: .bold))
                    
                    Text(NSLocalizedString("lighting_single_zone_note", comment: ""))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                // Success / Error Banner
                if viewModel.showSuccessAlert {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.razerSuccess)
                        Text(NSLocalizedString("lighting_applied_success", comment: ""))
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Button("Dismiss") {
                            viewModel.showSuccessAlert = false
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.razerSuccess.opacity(0.12))
                    .cornerRadius(6)
                }
                
                // Effect Picker Card
                VStack(alignment: .leading, spacing: 14) {
                    Text(NSLocalizedString("lighting_effect", comment: ""))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.razerGreen)
                    
                    Picker(NSLocalizedString("lighting_effect", comment: ""), selection: $viewModel.effect) {
                        ForEach(LightingEffectType.allCases, id: \.self) { eff in
                            Text(eff.displayName).tag(eff)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .razerCard()
                
                // Color Selection Card (if effect supports color)
                if viewModel.effect == .static || viewModel.effect == .breathingSingle || viewModel.effect == .breathingDual {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(NSLocalizedString("lighting_primary_color", comment: ""))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 20) {
                            ColorPicker("", selection: $viewModel.primaryColor, supportsOpacity: false)
                                .labelsHidden()
                            
                            // Presets
                            HStack(spacing: 10) {
                                SwatchButton(color: RGBColor.razerGreen.color) { viewModel.primaryColor = RGBColor.razerGreen.color }
                                SwatchButton(color: RGBColor.red.color) { viewModel.primaryColor = RGBColor.red.color }
                                SwatchButton(color: RGBColor.blue.color) { viewModel.primaryColor = RGBColor.blue.color }
                                SwatchButton(color: RGBColor.yellow.color) { viewModel.primaryColor = RGBColor.yellow.color }
                                SwatchButton(color: RGBColor.purple.color) { viewModel.primaryColor = RGBColor.purple.color }
                                SwatchButton(color: RGBColor.white.color) { viewModel.primaryColor = RGBColor.white.color }
                            }
                        }
                        
                        if viewModel.effect == .breathingDual {
                            Divider()
                            Text(NSLocalizedString("lighting_secondary_color", comment: ""))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 20) {
                                ColorPicker("", selection: $viewModel.secondaryColor, supportsOpacity: false)
                                    .labelsHidden()
                                
                                HStack(spacing: 10) {
                                    SwatchButton(color: RGBColor.razerGreen.color) { viewModel.secondaryColor = RGBColor.razerGreen.color }
                                    SwatchButton(color: RGBColor.red.color) { viewModel.secondaryColor = RGBColor.red.color }
                                    SwatchButton(color: RGBColor.blue.color) { viewModel.secondaryColor = RGBColor.blue.color }
                                    SwatchButton(color: RGBColor.yellow.color) { viewModel.secondaryColor = RGBColor.yellow.color }
                                    SwatchButton(color: RGBColor.purple.color) { viewModel.secondaryColor = RGBColor.purple.color }
                                    SwatchButton(color: RGBColor.white.color) { viewModel.secondaryColor = RGBColor.white.color }
                                }
                            }
                        }
                    }
                    .razerCard()
                }
                
                // Wave Direction Card (if wave selected)
                if viewModel.effect == .wave {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(NSLocalizedString("lighting_wave_dir", comment: ""))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Picker(NSLocalizedString("lighting_wave_dir", comment: ""), selection: $viewModel.waveDirection) {
                            Text(NSLocalizedString("lighting_dir_left", comment: "")).tag(UInt8(1))
                            Text(NSLocalizedString("lighting_dir_right", comment: "")).tag(UInt8(2))
                        }
                        .pickerStyle(.segmented)
                    }
                    .razerCard()
                }
                
                // Brightness Card
                VStack(alignment: .leading, spacing: 14) {
                    Text(NSLocalizedString("lighting_brightness", comment: ""))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        Image(systemName: "sun.min.fill")
                            .foregroundColor(.secondary)
                        
                        Slider(value: $viewModel.brightness, in: 0...1.0)
                            .accentColor(.razerGreen)
                        
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.razerGreen)
                        
                        Text("\(Int(viewModel.brightness * 100))%")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .frame(width: 45, alignment: .trailing)
                    }
                }
                .razerCard()
                
                // Indicator LEDs Card
                VStack(alignment: .leading, spacing: 14) {
                    Text(NSLocalizedString("lighting_indicator_leds", comment: ""))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Toggle(NSLocalizedString("lighting_game_led", comment: ""), isOn: $viewModel.gameModeLED)
                        .toggleStyle(.switch)
                    
                    Toggle(NSLocalizedString("lighting_macro_led", comment: ""), isOn: $viewModel.macroModeLED)
                        .toggleStyle(.switch)
                }
                .razerCard()
                
                // Action Buttons
                HStack(spacing: 14) {
                    Button(action: {
                        viewModel.applyLighting()
                    }) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text(NSLocalizedString("lighting_apply_btn", comment: ""))
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.razerGreen)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        viewModel.resetToDefaults()
                    }) {
                        Text(NSLocalizedString("lighting_reset_btn", comment: ""))
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.razerCardHover)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
            }
            .padding(24)
        }
    }
}

public struct SwatchButton: View {
    public let color: Color
    public let action: () -> Void
    
    public var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
                .overlay(Circle().stroke(Color.razerBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
