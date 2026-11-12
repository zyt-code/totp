import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    convenience init(rootView: some View) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 460),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "设置"
        window.isReleasedWhenClosed = false
        let host = NSHostingView(rootView: rootView)
        window.contentView = host
        window.setContentSize(NSSize(width: 440, height: max(host.fittingSize.height, 240)))
        window.center()
        self.init(window: window)
        window.delegate = self
    }

    func show() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        guard let window else { return }
        if !window.isVisible { window.center() }
        window.makeKeyAndOrderFront(nil)
    }
}

extension SettingsWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let closing = notification.object as? NSWindow else { return }
        restoreMenuBarOnlyIfNoEditors(excluding: closing)
    }
}
