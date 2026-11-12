# Design

## Context

「新增」目前是禁用按钮。`AccountMetadataRepository` 和 `SecretStore` 已经能保存账户。列表在应用启动时加载一次。行为见本变更的规格。

## Goals / Non-Goals

**Goals:**

- Base32 解码可单独测试。
- 保存走现有两个仓库，成功后列表重新加载。
- 录入窗口与菜单列表分开。

**Non-Goals:**

- 屏幕扫描、Vision、CSV、编辑已有账户、二维码。

## Decisions

### 1. Base32 放在 TOTPCore

`decodeBase32(_:)` 去掉空格、连字符并转成大写。字母表是 `A-Z` 和 `2-7`。`=` 只允许出现在末尾，长度必须能被 8 整除。空结果抛 `AppError.invalidSecret`。返回 `Data`，不返回可打印的 secret。

不引入 Base32 依赖。

### 2. 保存是一个函数

`saveAccount(siteName:username:secret:algorithm:digits:period:metadata:secrets:)`：

- 网站名去掉首尾空白，空则抛 `AppError.blankSiteName`。
- Secret 用 `decodeBase32`。
- 生成一个新 id，先写 secret，再写元数据。元数据字段不含 secret。
- 任一步失败则删除刚写入的 secret，避免只留下半条记录。

测试使用现有内存仓库。

### 3. 窗口与刷新

`TOTPApp` 持有账户数组。新增按钮启用，打开一个 `Window`。表单默认 SHA-1、6 位、30 秒。保存成功后关闭窗口，并在主线程重新调用 `loadAccounts`。失败时窗口保留，并显示错误文本。

设置仍禁用。应用不引用 ScreenCaptureKit、Vision 或 CSV。

### 4. 算法兼容

表单把所选算法、位数和周期原样写入元数据。列表继续调用现有 `totp`，因此 SHA-1、SHA-256、SHA-512 与 6/8 位不变。

### 5. 屏幕录制和 CSV

本变更没有扫描或导入，所以没有权限流程，也没有 CSV 列。以后做扫描时再单独查屏幕录制权限；拒绝后不抓屏。

## Risks / Trade-offs

- [菜单窗口里再开一个 SwiftUI Window 可能落到别的桌面] → 使用独立 `Window`，不用菜单内 Sheet；保存后重新加载列表即可。
- [先写 secret 再写元数据，崩溃时可能留下孤立 secret] → 保存函数在元数据失败时删除 secret；崩溃窗口不处理。
- [真实 Keychain 仍可能因未签名而写入失败] → 表单显示错误，不关闭窗口。

## Migration Plan

无旧数据。回滚是重新禁用新增按钮。

## Open Questions

无。
