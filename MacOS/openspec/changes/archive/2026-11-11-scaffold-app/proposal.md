# Proposal

## Why

仓库目前只有 OpenSpec 配置，没有可编译的应用或测试目标。后续的 TOTP、导入和屏幕识别都需要先落在一个 macOS 14+ 菜单栏工程里，并且把算法与界面拆开，才能单独验证。

## What Changes

- 新增 Swift Package 工程：一个 macOS 14+ 菜单栏可执行目标，加上一个不含 UI 的 TOTP 库目标。
- 应用以 `LSUIElement` 启动，只在菜单栏显示一个占位菜单：列表占位、分隔线、新增、设置、退出。退出能结束进程；其余菜单项只占位，不实现录入、导入或扫描。
- TOTP 库暴露密钥材料类型、RFC 4226 HOTP 与 RFC 6238 TOTP 的计算入口，算法覆盖 SHA-1、SHA-256、SHA-512，位数覆盖 6 和 8。本变更只要求接口与官方测试向量可测，不接账户存储。
- 密钥类型禁止 `CustomStringConvertible` 等会把 secret 打进日志或描述的接口；本变更不持久化 secret。
- 增加 Swift Testing 目标，用 RFC 6238 官方测试向量覆盖库，不引入第三方依赖。
- 屏幕录制权限、CSV 导入、剪贴板复制、Keychain 持久化留到后续变更。

## Capabilities

### New Capabilities

- `app-skeleton`: 菜单栏应用壳能启动并退出，TOTP 库能按 RFC 4226/6238 计算验证码且不把 secret 暴露到字符串描述。

### Modified Capabilities

- （无）

## Impact

- 新增 `Package.swift`、`Sources/TOTPApp`、`Sources/TOTPCore`、`Tests/TOTPCoreTests`。
- 可执行目标依赖 SwiftUI，库目标只依赖 Foundation 与 CryptoKit。
- 不新增网络、第三方包、账户存储或权限声明。
