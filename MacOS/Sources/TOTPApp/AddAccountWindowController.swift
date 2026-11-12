import AppKit
import SwiftUI

private final class KeyEntryWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class AddAccountWindowController: NSWindowController {
    convenience init(rootView: some View) {
        let window = KeyEntryWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 280),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "新增 TOTP 账户"
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = NSHostingView(rootView: rootView)
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
        window.makeFirstResponder(window.contentView)
    }

    func resize(to height: Double) {
        guard height > 1, let window else { return }
        let size = NSSize(width: 380, height: height)
        guard window.contentRect(forFrameRect: window.frame).height != height else { return }
        window.setContentSize(size)
    }
}

extension AddAccountWindowController: NSWindowDelegate {
    // 取消、保存成功、Esc 和红叉最终都走 close，这里统一把 Dock 图标收回去。
    func windowWillClose(_ notification: Notification) {
        guard let closing = notification.object as? NSWindow else { return }
        restoreMenuBarOnlyIfNoEditors(excluding: closing)
    }
}
