import Foundation
import CoreGraphics
import AppKit

public protocol MacroEngineProtocol: ObservableObject {
    var isPlaying: Bool { get }
    var isRecording: Bool { get }
    var recordedEvents: [MacroEvent] { get }
    func play(macro: Macro, completion: ((Bool) -> Void)?)
    func stopPlayback()
    func startRecording()
    func stopRecording() -> [MacroEvent]
}

public final class MacroEngine: MacroEngineProtocol, ObservableObject {
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var isRecording: Bool = false
    @Published public private(set) var recordedEvents: [MacroEvent] = []
    
    private var playbackQueue = DispatchQueue(label: "app.momentoid.razercontrol.macro", qos: .userInteractive)
    private var isCancelled = false
    private var activeKeys: Set<CGKeyCode> = []
    private var recordingMonitor: Any?
    private var lastRecordedTime: Date?
    
    public init() {}
    
    deinit {
        stopPlayback()
        if isRecording {
            _ = stopRecording()
        }
    }
    
    public func play(macro: Macro, completion: ((Bool) -> Void)? = nil) {
        guard !isPlaying else { return }
        
        DispatchQueue.main.async {
            self.isPlaying = true
        }
        self.isCancelled = false
        
        playbackQueue.async { [weak self] in
            guard let self = self else { return }
            
            let repeats = max(1, macro.repeatCount)
            var success = true
            
            for _ in 0..<repeats {
                if self.isCancelled {
                    success = false
                    break
                }
                
                for event in macro.events {
                    if self.isCancelled {
                        success = false
                        break
                    }
                    
                    switch event.type {
                    case .delay:
                        let ms = event.delayMs ?? 50
                        usleep(useconds_t(ms * 1000))
                        
                    case .keyDown:
                        guard let code = event.keyCode else { continue }
                        let cgKey = CGKeyCode(code)
                        self.activeKeys.insert(cgKey)
                        let downEv = CGEvent(keyboardEventSource: nil, virtualKey: cgKey, keyDown: true)
                        downEv?.post(tap: .cghidEventTap)
                        usleep(10000) // 10ms default delay between events
                        
                    case .keyUp:
                        guard let code = event.keyCode else { continue }
                        let cgKey = CGKeyCode(code)
                        self.activeKeys.remove(cgKey)
                        let upEv = CGEvent(keyboardEventSource: nil, virtualKey: cgKey, keyDown: false)
                        upEv?.post(tap: .cghidEventTap)
                        usleep(10000)
                    }
                }
            }
            
            // Release any keys still active
            self.releaseActiveKeys()
            
            DispatchQueue.main.async {
                self.isPlaying = false
                completion?(success)
            }
        }
    }
    
    public func stopPlayback() {
        isCancelled = true
        releaseActiveKeys()
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
    
    private func releaseActiveKeys() {
        for key in activeKeys {
            let upEv = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: false)
            upEv?.post(tap: .cghidEventTap)
        }
        activeKeys.removeAll()
    }
    
    // MARK: - Recording
    
    public func startRecording() {
        guard !isRecording else { return }
        recordedEvents.removeAll()
        lastRecordedTime = Date()
        isRecording = true
        
        recordingMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self = self, self.isRecording else { return event }
            
            let now = Date()
            if let last = self.lastRecordedTime {
                let diffMs = UInt32(max(10, min(2000, now.timeIntervalSince(last) * 1000)))
                self.recordedEvents.append(MacroEvent(type: .delay, delayMs: diffMs))
            }
            self.lastRecordedTime = now
            
            let type: MacroActionType = (event.type == .keyDown) ? .keyDown : .keyUp
            let keyName = event.charactersIgnoringModifiers?.uppercased() ?? "Key \(event.keyCode)"
            self.recordedEvents.append(MacroEvent(type: type, keyCode: event.keyCode, keyName: keyName))
            
            return event
        }
    }
    
    public func stopRecording() -> [MacroEvent] {
        isRecording = false
        if let monitor = recordingMonitor {
            NSEvent.removeMonitor(monitor)
            recordingMonitor = nil
        }
        return recordedEvents
    }
}
