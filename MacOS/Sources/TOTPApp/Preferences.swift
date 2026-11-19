import Foundation

// 偏好键集中一处，避免字符串拼错，默认值也只在这里出现。
enum SettingKey {
    static let clipboardAutoClear = "clipboardAutoClear"
    static let clipboardClearDelay = "clipboardClearDelay"
    static let groupCodes = "groupCodes"

    static let defaultClipboardAutoClear = true
    static let defaultClipboardClearDelay = 30
    static let defaultGroupCodes = true
}

enum AppInfo {
    static let name = "TOTP"
    static let version = "2.0.0"
    static let storageStatus = "本地 Keychain 加密存储 · 零网络权限"
}
