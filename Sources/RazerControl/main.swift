import AppKit
import SwiftUI
import RazerControlKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 1024, height: 700),
    styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
    backing: .buffered,
    defer: false
)

window.center()
window.title = "Razer Control"
window.minSize = NSSize(width: 920, height: 640)
window.titlebarAppearsTransparent = true
window.titleVisibility = .hidden
window.isReleasedWhenClosed = false
window.contentView = NSHostingView(rootView: MainView())
window.makeKeyAndOrderFront(nil)

delegate.window = window

app.run()
