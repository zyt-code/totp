# Proposal

## Why

在全仓库代码 review 中，发现了多处跨端一致性、UI 反馈以及并发健壮性问题：
1. Android 相机扫码每秒向识别器投递连续帧，在导航返回前几帧均会触发成功回调，导致同一账户在毫秒内被重复保存多次；
2. Android 扫码页选图失败或识别错误时，由于 `SnackbarHost` 仅挂载在主页，扫码页无法呈现错误 Snackbar；
3. macOS 设置页的“登录时自动启动”开关在失败时重置状态会二次触发 SwiftUI `.onChange`，导致捕获的错误信息被立即清空；
4. macOS 仅实现了备份导出，未实现备份导入，与 README 中“两端互相可导入”的承诺及跨端迁移需求不符；
5. Android 的重命名实现错误调用了 `displayTitle`，在包含冒号或重复单词时产生非预期的拆分和折叠，偏离“按首个空格拆分”的规格；
6. `macos/totp-list` 仍残留 1.0 的 URL 解码需求，与统一由 `totp-core` 派生展示名称的 2.0 规范冲突。

本变更旨在系统性修复上述问题，对齐双端规格与实现，消除健壮性漏洞并保持代码库整洁。

## What Changes

- **Android 扫码防重入**：在 `ScanScreen` / 保存流程中引入处理态标志锁（防抖防重），扫码成功触发后立即冻结后续帧回调，确保单次扫码只保存一次。
- **Android 扫码页反馈补全**：在 `ScanScreen` 内部（或应用顶层）提供 Material 3 `SnackbarHost`，确保相册挑选失败或无效码时在扫码页即时弹出错误通知。
- **Android 重命名对齐**：修改 `AccountStore.rename`，严格按输入名称的首个空格拆分为站点名与用户名，与 macOS 及规格行为一致。
- **Android 数据库事务与 IO 异常防护**：使用 Room 事务保证 `accounts` 元数据与 `secrets` 密文的原子读写；对文件导出/导入中的 `openOutputStream`/`openInputStream` 增加异常捕获并给与错误反馈。
- **macOS 设置项响应流重构**：重构 `SettingsView` 中的登录项 Toggle，使用自定义 `Binding` 或防循环机制，确保注销/注册失败时错误提示稳定显示且不引发级联注销。
- **macOS 补充备份导入**：在 `SettingsView` 数据区补充“导入备份（JSON）”按钮与文件选择器，复用 `totp-core` 的 `import_backup_json` 逻辑，支持完整的 JSON 备份恢复与结果提示。
- **macOS 列表展示规格同步**：更新 `openspec/specs/macos/totp-list/spec.md`，清理遗留的 URL 编码解码描述，明确引用 `totp-core` 的 `Display name normalization`。
- **测试代码清理**：清理 `MacOS/Tests/TOTPCoreTests/AccountManagementTests.swift` 中宏断言的多余 `try` 标记，消除 Swift 6 编译器警告。

## Capabilities

### New Capabilities
无。

### Modified Capabilities
- `android/account-capture`: 增加相机连续扫码防重入约束；规范相册选取/解析失败时在当前扫码界面呈现 Snackbar。
- `android/account-list`: 明确重命名规则按首个空格拆分，不执行冒号优先及 token 折叠。
- `macos/app-settings`: 明确登录项注册失败时错误信息必须稳定展示且不被重置行为冲掉。
- `macos/backup-export`: 扩充为备份导出与导入，增加 JSON 备份导入规格（成功计数、失败跳过、格式错误提示）。
- `macos/totp-list`: 清除 1.0 遗留的 URL 解码条目，同步为依赖 `totp-core` 规范。

## Impact

- **代码影响**：
  - Android: `MainActivity.kt`, `ScanScreen.kt`, `AccountStore.kt`, `Home.kt`, `DisplayTest.kt`, `AccountStoreTest.kt`。
  - macOS: `SettingsView.swift`, `AccountManagementTests.swift`。
  - OpenSpec: `specs/android/account-capture/spec.md`, `specs/android/account-list/spec.md`, `specs/macos/app-settings/spec.md`, `specs/macos/backup-export/spec.md`, `specs/macos/totp-list/spec.md`。
- **行为影响**：
  - Android 扫码不再出现一次扫码新增两条以上相同记录的问题；选图失败能立即看到 Snackbar；重命名含冒号字符不会被误解析为 issuer。
  - macOS 设置增加导入功能，双端完整支持互相导入导出备份；登录项切换失败时有清晰红字报错。
- **兼容性**：完全向后兼容现有的 2.0 数据库架构与 JSON 备份文档（`totp-backup` v2）。
