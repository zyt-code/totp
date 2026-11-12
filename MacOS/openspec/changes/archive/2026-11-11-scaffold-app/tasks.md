# Tasks

## 1. Package

- [x] 1.1 添加 `Package.swift`：macOS 14，`TOTPCore` 库、`TOTPApp` 可执行目标、`TOTPCoreTests`。确认 `swift package describe` 列出这三个目标且无第三方依赖。
- [x] 1.2 给 `TOTPApp` 生成 `LSUIElement=true` 的 Info.plist。确认 `swift build` 成功，且产物 Info.plist 含该键。

## 2. TOTPCore

- [x] 2.1 添加 `HashAlgorithm`、`Secret` 和 `AppError`。`Secret` 不实现 `CustomStringConvertible`，`description` 与 `debugDescription` 为固定占位。用 Swift Testing 断言插值和调试描述不含原始字节、hex 或 Base32。
- [x] 2.2 实现 `hotp`：8 字节大端计数器、CryptoKit HMAC、RFC 4226 动态截断、6 或 8 位前导零。空密钥、负数计数器和非法位数抛 `AppError`，不用 force unwrap。测试断言 SHA-1 计数器 0 得到 `755224` 和 `84755224`，并用 RFC 6238 的 32 字节与 64 字节种子断言 SHA-256、SHA-512 的 6 位结果。
- [x] 2.3 实现 `totp`：`floor(unixTime / period)` 后调用 `hotp`，`period` 默认 30，非正 period 抛 `AppError`。测试断言 Unix 59、SHA-1、8 位为 `94287082`；Unix 1111111109、SHA-256、8 位为 `68084774`；再断言附录 B 的一行 SHA-512；默认 period 与显式 30 相同。

## 3. Menu bar shell

- [x] 3.1 添加 `MenuBarExtra`：禁用的列表占位、分隔线、禁用的新增、禁用的设置、启用的退出。退出调用终止。占位项没有账户、导入、扫描或剪贴板代码。确认 `swift build --product TOTPApp` 成功，且源码不引用 ScreenCaptureKit、Vision 或 Keychain。

## 4. Integration

- [x] 4.1 运行 `swift test`，确认 RFC 向量、非法输入和密钥描述测试全部通过。
