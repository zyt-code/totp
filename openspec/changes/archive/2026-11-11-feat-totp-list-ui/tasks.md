# Tasks

## 1. Row model

- [x] 1.1 添加 `TOTPAccount`、`remainingSeconds`、`ringFraction` 和 `currentCode`。用 Swift Testing 断言 Unix 59 时 SHA-1/8 位为 `94287082`、剩余 1 秒、进度为 1/30；周期边界剩余秒数回到周期长度。空列表不在这一任务处理。

## 2. Menu list

- [x] 2.1 用账户列表替换禁用的「TOTP 列表」按钮，保留分隔线、禁用的新增、禁用的设置和退出。悬停行显示验证码、环形进度和剩余秒数，离开后隐藏验证码；单击整行复制并显示「已复制」，2 秒后恢复。30 秒后仅当剪贴板仍是该码时清空。确认 `swift build --product TOTPApp` 成功，且源码不引用 Keychain、ScreenCaptureKit 或 Vision。

## 3. Integration

- [x] 3.1 运行 `swift test`，确认新增倒计时测试和原有 RFC 测试都通过。
