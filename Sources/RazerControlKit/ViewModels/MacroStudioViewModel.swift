import Foundation
import Combine

public final class MacroStudioViewModel: ObservableObject {
    public let appVM: AppViewModel
    
    @Published public var macros: [Macro] = []
    @Published public var selectedMacro: Macro?
    @Published public var isRecording: Bool = false
    @Published public var isPlaying: Bool = false
    @Published public var testFieldText: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(appVM: AppViewModel) {
        self.appVM = appVM
        self.macros = appVM.profileManager.activeProfile.macros
        self.selectedMacro = macros.first
        
        appVM.profileManager.$activeProfile
            .sink { [weak self] profile in
                guard let self = self else { return }
                self.macros = profile.macros
                if let sel = self.selectedMacro, !profile.macros.contains(where: { $0.id == sel.id }) {
                    self.selectedMacro = profile.macros.first
                }
            }
            .store(in: &cancellables)
            
        appVM.macroEngine.$isPlaying
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)
            
        appVM.macroEngine.$isRecording
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)
    }
    
    public func createMacro(name: String) {
        let macro = Macro(name: name, events: [
            MacroEvent(type: .keyDown, keyCode: 0, keyName: "A"),
            MacroEvent(type: .delay, delayMs: 50),
            MacroEvent(type: .keyUp, keyCode: 0, keyName: "A")
        ])
        var profile = appVM.profileManager.activeProfile
        profile.macros.append(macro)
        appVM.profileManager.updateActiveProfile(profile)
        self.selectedMacro = macro
    }
    
    public func deleteMacro(id: UUID) {
        var profile = appVM.profileManager.activeProfile
        profile.macros.removeAll(where: { $0.id == id })
        appVM.profileManager.updateActiveProfile(profile)
    }
    
    public func playSelectedMacro() {
        guard let macro = selectedMacro else { return }
        appVM.macroEngine.play(macro: macro)
    }
    
    public func stopPlayback() {
        appVM.macroEngine.stopPlayback()
    }
    
    public func startRecording() {
        appVM.macroEngine.startRecording()
    }
    
    public func stopRecording() {
        let events = appVM.macroEngine.stopRecording()
        guard var macro = selectedMacro else { return }
        macro.events = events
        var profile = appVM.profileManager.activeProfile
        if let idx = profile.macros.firstIndex(where: { $0.id == macro.id }) {
            profile.macros[idx] = macro
            appVM.profileManager.updateActiveProfile(profile)
            self.selectedMacro = macro
        }
    }
}
