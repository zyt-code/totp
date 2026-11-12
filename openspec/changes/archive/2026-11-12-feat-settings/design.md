# Design

## Context

齿轮按钮是禁用的空动作。剪贴板清理硬编码 30 秒，分段显示总是开启，登录启动与导出都不存在。`AddAccountWindowController` 已经在窗口关闭时恢复 `.accessory`，这段逻辑现在需要给第二个窗口复用。

## Goals / Non-Goals

**Goals:**

- 设置窗口与新增窗口同一套原生质感与激活策略。
- 三项偏好可持久化、可测试，且默认值与现有行为一致。
- 导出文件能被自己的解析器读回。

**Non-Goals:**

- 导入备份、云同步、主题切换、快捷键自定义。
- 改 TOTP 计算、Keychain 存储格式、账户列表布局。

## Decisions

### 1. 复用激活策略，而不是复制

把现有的「关闭后若无其他可见编辑窗口则恢复 `.accessory`」从 `AddAccountWindowController` 抽成一个小函数 `restoreMenuBarOnlyIfNoEditors(excluding:)`，两个控制器在 `windowWillClose` 里各调一次。排除 `NSPanel`，避免把菜单栏弹窗面板算成编辑窗口。

### 2. 设置窗口沿用现有控制器的骨架

新建 `SettingsWindowController`：`NSWindow` + `.closable` + `NSHostingView`，宽度 440、高度随内容。视图用 `Form { ... }.formStyle(.grouped)`。关闭按钮与 Esc 都走 `close()`，因此共用同一段恢复逻辑。

### 3. 偏好集中在 key 常量

`enum PreferenceKey` 放三个键：剪贴板开关、延迟秒数、分段显示。视图用 `@AppStorage(PreferenceKey.x)` 读写，默认值分别为 `true`、`30`、`true`。集中常量避免字符串拼错，也让默认值只有一处。

### 4. 剪贴板比对抽成纯函数

`shouldClearClipboard(current: String?, copied: String) -> Bool` 放在 `TOTPCore`，只做相等比较。视图负责按偏好睡眠并在到点时调用它。这样「不误删用户后来复制的内容」这条最关键的安全逻辑可以被单测覆盖，不依赖计时。

### 5. 分段显示作为参数

`formattedCode(_:grouped:)` 增加带默认值的参数，保持既有调用不变；关闭时原样返回。复制路径继续使用原始码，不经过格式化。

### 6. 导出需要 Base32 编码

现有代码只有解码。新增 `encodeBase32(_:)`（RFC 4648，大写、不带填充），`otpauthURI(for:)` 生成带 `secret`、`issuer`、`algorithm`、`digits`、`period` 的 URI，标签用 `issuer:account` 并做百分号编码。`otpauthBackup(accounts:)` 用换行连接。测试用「编码再解析」验证往返一致。

### 7. 登录启动用 SMAppService

`SMAppService.mainApp`：开启调 `register()`，关闭调 `unregister()`，窗口出现时用 `status == .enabled` 回填开关。失败时显示错误文本并把开关拨回真实状态。

### 8. 导出交互

先 `NSAlert` 确认，再 `NSSavePanel`（默认文件名 `totp-backup.txt`，纯文本）。取消任一步都不写文件。

## Risks / Trade-offs

- [未签名或非 `/Applications` 下的构建可能注册登录项失败] → 失败只提示、不崩溃；这是系统限制，不是逻辑缺陷。
- [`@AppStorage` 值变化不会自动重排已有倒计时] → 延迟改动只影响下一次复制，符合预期。
- [设置窗口与新增窗口同时打开时，关掉一个仍是 `.regular`] → 恢复函数按「是否还有其他可见编辑窗口」判断。

## Migration Plan

无数据迁移。既有用户首次启动即得到默认值（清理开、30 秒、分段开），与当前行为一致。

## Open Questions

无。
