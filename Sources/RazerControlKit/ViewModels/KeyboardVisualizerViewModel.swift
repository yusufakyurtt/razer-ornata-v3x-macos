import Foundation
import Combine

public final class KeyboardVisualizerViewModel: ObservableObject {
    public let appVM: AppViewModel
    
    @Published public var selectedKey: VisualKey?
    @Published public var activeMapping: KeyMapping?
    
    public let mainRows = KeyboardVisualizerLayout.defaultOrnataV3XLayout()
    public let numpadRows = KeyboardVisualizerLayout.defaultNumpadLayout()
    
    public init(appVM: AppViewModel) {
        self.appVM = appVM
    }
    
    public func selectKey(_ key: VisualKey) {
        self.selectedKey = key
        self.activeMapping = appVM.profileManager.activeProfile.keyMappings.first(where: { $0.sourceKeyCode == key.keyCode })
    }
    
    public func mappingForKey(_ key: VisualKey) -> KeyMapping? {
        return appVM.profileManager.activeProfile.keyMappings.first(where: { $0.sourceKeyCode == key.keyCode })
    }
}
