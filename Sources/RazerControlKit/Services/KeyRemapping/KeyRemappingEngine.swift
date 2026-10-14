import Foundation
import CoreGraphics
import AppKit

public protocol KeyRemappingEngineProtocol: AnyObject {
    var isRunning: Bool { get }
    func start() -> Bool
    func stop()
    func updateMappings(_ mappings: [KeyMapping])
}

public final class KeyRemappingEngine: KeyRemappingEngineProtocol {
    public private(set) var isRunning: Bool = false
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var mappings: [UInt16: KeyMapping] = [:]
    private var pressedSyntheticKeys: Set<CGKeyCode> = []
    private let lock = NSLock()
    
    public init() {}
    
    deinit {
        stop()
    }
    
    public func updateMappings(_ newMappings: [KeyMapping]) {
        lock.lock()
        defer { lock.unlock() }
        mappings.removeAll()
        for m in newMappings where m.isEnabled {
            mappings[m.sourceKeyCode] = m
        }
    }
    
    public func start() -> Bool {
        guard !isRunning else { return true }
        
        // Event mask for KeyDown, KeyUp, and FlagsChanged
        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                        (1 << CGEventType.keyUp.rawValue) |
                        (1 << CGEventType.flagsChanged.rawValue)
        
        let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else {
                    return Unmanaged.passRetained(event)
                }
                let engine = Unmanaged<KeyRemappingEngine>.fromOpaque(refcon).takeUnretainedValue()
                return engine.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: observer
        ) else {
            return false
        }
        
        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        isRunning = true
        return true
    }
    
    public func stop() {
        guard isRunning else { return }
        lock.lock()
        defer { lock.unlock() }
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let src = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
                self.runLoopSource = nil
            }
            self.eventTap = nil
        }
        
        // Clean up any remaining synthetic pressed keys to avoid stuck keys
        for key in pressedSyntheticKeys {
            let upEvent = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: false)
            upEvent?.post(tap: .cghidEventTap)
        }
        pressedSyntheticKeys.removeAll()
        
        isRunning = false
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }
        
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        
        lock.lock()
        guard let mapping = mappings[keyCode] else {
            lock.unlock()
            return Unmanaged.passRetained(event)
        }
        lock.unlock()
        
        let isKeyDown = (type == .keyDown)
        let isKeyUp = (type == .keyUp)
        
        switch mapping.actionType {
        case .disable:
            // Drop event completely
            return nil
            
        case .remapKey:
            guard let target = mapping.targetKeyCode else {
                return Unmanaged.passRetained(event)
            }
            
            event.setIntegerValueField(.keyboardEventKeycode, value: Int64(target))
            if isKeyDown {
                pressedSyntheticKeys.insert(CGKeyCode(target))
            } else if isKeyUp {
                pressedSyntheticKeys.remove(CGKeyCode(target))
            }
            return Unmanaged.passRetained(event)
            
        case .modifierCombo:
            guard let target = mapping.targetKeyCode else {
                return Unmanaged.passRetained(event)
            }
            
            event.setIntegerValueField(.keyboardEventKeycode, value: Int64(target))
            var flags = event.flags
            if mapping.targetModifiers.contains(.command) { flags.insert(.maskCommand) }
            if mapping.targetModifiers.contains(.option)  { flags.insert(.maskAlternate) }
            if mapping.targetModifiers.contains(.control) { flags.insert(.maskControl) }
            if mapping.targetModifiers.contains(.shift)   { flags.insert(.maskShift) }
            event.flags = flags
            return Unmanaged.passRetained(event)
            
        case .mediaControl:
            if isKeyDown, let action = mapping.mediaAction {
                executeMediaAction(action)
            }
            return nil
            
        case .launchApp:
            if isKeyDown, let appPath = mapping.appPath {
                let url = URL(fileURLWithPath: appPath)
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            }
            return nil
            
        case .macro:
            // Handled via Notification or MacroEngine
            if isKeyDown, let macroId = mapping.macroId {
                NotificationCenter.default.post(name: NSNotification.Name("RazerTriggerMacro"), object: macroId)
            }
            return nil
        }
    }
    
    private func executeMediaAction(_ action: MediaControlAction) {
        let key: Int32
        switch action {
        case .playPause: key = 16 // NX_KEYTYPE_PLAY
        case .nextTrack: key = 17 // NX_KEYTYPE_NEXT
        case .previousTrack: key = 18 // NX_KEYTYPE_PREVIOUS
        case .volumeUp: key = 0 // NX_KEYTYPE_SOUND_UP
        case .volumeDown: key = 1 // NX_KEYTYPE_SOUND_DOWN
        case .mute: key = 7 // NX_KEYTYPE_MUTE
        }
        
        func postMediaKey(down: Bool) {
            let flags: NSEvent.ModifierFlags = down ? .init(rawValue: 0xa00) : .init(rawValue: 0xb00)
            let data1 = Int((key << 16) | (down ? 0xa00 : 0xb00))
            let ev = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: flags,
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8,
                data1: data1,
                data2: -1
            )
            ev?.cgEvent?.post(tap: .cghidEventTap)
        }
        
        postMediaKey(down: true)
        usleep(5000)
        postMediaKey(down: false)
    }
}
