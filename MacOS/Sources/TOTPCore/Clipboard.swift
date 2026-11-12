import Foundation

// 到点时只清理仍等于刚复制的验证码的内容，避免误删用户后来复制的东西。
public func shouldClearClipboard(current: String?, copied: String) -> Bool {
    current == copied
}
