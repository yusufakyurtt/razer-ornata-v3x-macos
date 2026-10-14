import AppKit
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public var window: NSWindow?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            window?.makeKeyAndOrderFront(nil)
        }
        return true
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        // Notification for cleanup
    }
}
