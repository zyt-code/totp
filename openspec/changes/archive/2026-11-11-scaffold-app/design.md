# Design

## Context

仓库没有应用代码。行为见 `specs/app-skeleton/spec.md`；本文件只决定工程形态和算法边界。

## Goals / Non-Goals

**Goals:**

- 一个 `swift test` 能跑的 Swift Package：菜单栏可执行目标 + 无 UI 的 TOTP 库。
- 库用 CryptoKit 实现 RFC 4226 动态截断，TOTP 只是 `floor(unixTime / period)` 后调用 HOTP。
- SHA-1、SHA-256、SHA-512 与 6/8 位都能走同一条截断路径。

**Non-Goals:**

- 账户、Keychain、剪贴板、CSV、屏幕录制、otpauth URL、时钟偏移窗口。
- Xcode 工程、签名、公证、应用图标。

## Decisions

### 1. Swift Package，而不是 Xcode 工程

`Package.swift` 三个目标：

| 目标 | 类型 | 依赖 | 平台 |
|---|---|---|---|
| `TOTPCore` | library | Foundation、CryptoKit | macOS 14 |
| `TOTPApp` | executable | `TOTPCore`、SwiftUI | macOS 14 |
| `TOTPCoreTests` | test | `TOTPCore`、Swift Testing | macOS 14 |

不生成 `.xcodeproj`。`swift test` 不需要签名或 Info.plist，就能验证算法。可执行目标用 SwiftPM 的 `Info.plist` 生成项设置 `LSUIElement = true`。

备选：Xcode app target。否决，因为空仓库上多一套工程文件，而测试并不需要它。

### 2. 菜单只做占位

`TOTPApp` 用 SwiftUI `MenuBarExtra`。菜单五项固定：禁用的列表占位、分隔线、禁用的新增、禁用的设置、启用的退出。退出调用 `NSApplication.shared.terminate`。应用不链接 ScreenCaptureKit 或 Vision，也不声明屏幕录制权限。

### 3. 算法只放在 TOTPCore

公开面保持最小：

- `HashAlgorithm`：`sha1`、`sha256`、`sha512`
- `Secret`：持有 `Data`。不实现 `CustomStringConvertible`；`description` 与 `debugDescription` 使用固定占位文本，不含字节、hex 或 Base32。
- `hotp(secret:counter:algorithm:digits:) throws -> String`
- `totp(secret:time:algorithm:digits:period:) throws -> String`，`period` 默认 30

计数器编码为 8 字节大端。HMAC 用 `CryptoKit.HMAC`，按算法选择 `Insecure.SHA1`、`SHA256`、`SHA512`。动态截断与 RFC 4226 一致，结果用前导零补到指定位数。

`AppError` 只覆盖本变更会抛的情况：空密钥、负数计数器、位数不是 6 或 8、period 小于等于 0。用 `throws`，不用 `Result`，也不使用 `!`。

### 4. 测试向量按 RFC 的种子长度

RFC 6238 附录 B 的种子不是同一串：

- SHA-1：ASCII `12345678901234567890`（20 字节）
- SHA-256：该串重复到 32 字节
- SHA-512：该串重复到 64 字节

必须覆盖的向量：

- HOTP SHA-1、6 位、计数器 0 → `755224`（RFC 4226）
- HOTP SHA-1、8 位、计数器 0 → `84755224`（同一截断值）
- TOTP SHA-1、8 位、30 秒、Unix 59 → `94287082`
- TOTP SHA-256、8 位、30 秒、Unix 1111111109 → `68084774`
- 同表再取 SHA-512 一行，防止算法枚举接错

不把 RFC 附录 A 的 Java 参考实现复制进仓库。

### 5. 屏幕录制与 CSV 不在本变更

两者都还没有行为。屏幕录制以后单独做：先查 `CGPreflightScreenCaptureAccess`，未授权时给出打开系统设置的路径，拒绝后菜单保持可用且不抓屏。CSV 以后单独定义列映射和坏行跳过。本变更不预留这些类型。

## Risks / Trade-offs

- [SwiftPM 可执行目标的菜单栏生命周期比 Xcode app 薄] → 本变更只要求菜单出现且退出有效；签名和登录项留到打包变更。
- [SHA-1 在 CryptoKit 里位于 `Insecure`] → RFC 4226 与常见验证器仍要求它，所以保留，并限制在 HMAC 用途。
- [密钥仍以明文留在进程内存] → 本变更不落盘；持久化变更必须改走 Keychain 或 AES-GCM。

## Migration Plan

新仓库，无数据迁移。回滚就是删除 `Package.swift`、`Sources/` 和 `Tests/`。

## Open Questions

无。打包形态和账户存储会改变后续变更的范围，但不改变本变更的规格或任务。
