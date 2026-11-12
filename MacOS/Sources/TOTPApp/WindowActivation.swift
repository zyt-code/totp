import AppKit

// 关闭编辑窗口后，若已无其他可见编辑窗口，就收回 Dock 图标。
// 排除 NSPanel，避免把菜单栏弹窗面板算成编辑窗口。
@MainActor
func restoreMenuBarOnlyIfNoEditors(excluding closing: NSWindow) {
    let otherEditors = NSApp.windows.contains { window in
        window !== closing && window.isVisible && window.canBecomeMain && !(window is NSPanel)
    }
    if !otherEditors {
        NSApp.setActivationPolicy(.accessory)
    }
}
