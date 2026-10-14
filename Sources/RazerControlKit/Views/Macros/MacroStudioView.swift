import SwiftUI

public struct MacroStudioView: View {
    @StateObject private var viewModel: MacroStudioViewModel
    @State private var newMacroNameText: String = ""
    @State private var showNewModal: Bool = false
    
    public init(appVM: AppViewModel) {
        _viewModel = StateObject(wrappedValue: MacroStudioViewModel(appVM: appVM))
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("macro_title", comment: ""))
                            .font(.system(size: 24, weight: .bold))
                        
                        Text(NSLocalizedString("macro_desc", comment: ""))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showNewModal = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text(NSLocalizedString("macro_new_btn", comment: ""))
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
                
                // Macro Selection & Recording Controls
                HStack(spacing: 14) {
                    Picker("Macro", selection: $viewModel.selectedMacro) {
                        ForEach(viewModel.macros) { macro in
                            Text(macro.name).tag(Optional(macro))
                        }
                    }
                    .frame(width: 240)
                    
                    if viewModel.isRecording {
                        Button(action: {
                            viewModel.stopRecording()
                        }) {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                Text(NSLocalizedString("macro_stop_record_btn", comment: ""))
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.razerDanger)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: {
                            viewModel.startRecording()
                        }) {
                            HStack {
                                Circle().fill(Color.red).frame(width: 8, height: 8)
                                Text(NSLocalizedString("macro_record_btn", comment: ""))
                            }
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.razerCardHover)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if viewModel.isPlaying {
                        Button(action: {
                            viewModel.stopPlayback()
                        }) {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text(NSLocalizedString("macro_stop_btn", comment: ""))
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.razerWarning)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: {
                            viewModel.playSelectedMacro()
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text(NSLocalizedString("macro_play_btn", comment: ""))
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.razerGreen)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                }
                .razerCard()
                
                // Macro Event Sequence
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Event Sequence")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.razerGreen)
                        
                        Spacer()
                        
                        if let count = viewModel.selectedMacro?.events.count {
                            Text("\(count) action(s)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let events = viewModel.selectedMacro?.events, !events.isEmpty {
                        VStack(spacing: 6) {
                            ForEach(Array(events.enumerated()), id: \.offset) { idx, event in
                                HStack {
                                    Text("\(idx + 1).")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(width: 25, alignment: .leading)
                                    
                                    Image(systemName: event.type == .delay ? "clock" : (event.type == .keyDown ? "arrow.down.square.fill" : "arrow.up.square.fill"))
                                        .foregroundColor(event.type == .delay ? .razerWarning : .razerGreen)
                                    
                                    Text(event.type == .delay ? "Delay: \(event.delayMs ?? 0) ms" : (event.type == .keyDown ? "Key Down: \(event.keyName ?? "Key")" : "Key Up: \(event.keyName ?? "Key")"))
                                        .font(.system(size: 12, weight: .medium))
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.razerCardHover.opacity(0.6))
                                .cornerRadius(4)
                            }
                        }
                    } else {
                        Text("No events recorded in this macro. Click 'Record Sequence' to capture typing.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(20)
                    }
                }
                .razerCard()
                
                // Dedicated Harmless Test Field
                VStack(alignment: .leading, spacing: 10) {
                    Text("Macro Test Playground")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Test macro keystroke output safely inside this text area without affecting external applications.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $viewModel.testFieldText)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(red: 0.09, green: 0.09, blue: 0.09))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.razerBorder, lineWidth: 1)
                        )
                    
                    HStack {
                        Spacer()
                        Button("Clear Test Output") {
                            viewModel.testFieldText = ""
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    }
                }
                .razerCard()
            }
            .padding(24)
        }
        .sheet(isPresented: $showNewModal) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Create New Macro")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.razerGreen)
                
                TextField("Macro Name", text: $newMacroNameText)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    Spacer()
                    Button("Cancel") {
                        showNewModal = false
                        newMacroNameText = ""
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    
                    Button("Create") {
                        viewModel.createMacro(name: newMacroNameText)
                        showNewModal = false
                        newMacroNameText = ""
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
