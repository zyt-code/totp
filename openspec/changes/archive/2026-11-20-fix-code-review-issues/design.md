# Design

## Context

见 `proposal.md - Why`。
当前仓库在跨平台 Rust 核心之上构建了 macOS 与 Android 两套独立的前端实现。代码审查发现两端在错误处理、UI 反馈、并发防抖与功能对齐上存在若干技术断层。本设计明确各项修复的具体实现方案。

## Goals / Non-Goals

**Goals:**
- 消除 Android 相机扫码在帧流中连续多次入库的并发缺陷。
- 在 Android 扫码页提供即时的 Material 3 Snackbar 错误反馈。
- 解决 macOS 设置页切换登录项时由于 SwiftUI `.onChange` 循环重置引发的错误信息被抹除问题。
- 在 macOS 设置窗口中补全 JSON 备份导入功能，实现与 Android 端的对等互通。
- 将 Android 端账户重命名逻辑修正为严格按首个空格拆分，与 macOS 及规范对齐。
- 为 Android 数据库操作提供原子事务保障，并增强文件导出/导入的 IO 容错。
- 消除 Swift 6 编译器在测试代码中的多余 `try` 警告。

**Non-Goals:**
- 不修改 Rust `core/` 的基础加密算法与 Base32 规则。
- 不改动 JSON 备份协议的 schema（维持 `format=totp-backup`, `version=2`）。
- 不引入新的外部依赖或第三方库。

## Decisions

### 1. Android 相机扫码防重入标志
- **决策**：在 `ScanScreen.kt` 内维护 `var isProcessing by remember { mutableStateOf(false) }`。
- **机制**：
  - 当 ML Kit 识别出有效载荷且 `acceptPayloads` 返回 `CaptureResult.Saved` 时，在调用 `onResult` 前首先检查 `if (isProcessing) return@addOnSuccessListener`，随后立即置 `isProcessing = true`。
  - 当页面销毁或重新激活时重置该状态。
- **备选考虑**：在 `MainActivity.kt` 的 `save` 协程中加互斥锁。否决原因：CameraX 分析器仍会在回调队列中排队投递图像帧，在视图层尽早丢弃无效帧开销更低。

### 2. Android 扫码界面错误反馈架构
- **决策**：在 `ScanScreen.kt` 内部建立专用的 `SnackbarHostState` 与 `SnackbarHost`。
- **机制**：
  - 将 `ScanScreen` 的根布局扩展为包含自身 `SnackbarHost(snackbarHostState)` 的全屏容器，或通过参数接收错误通知调度。
  - 从相册选取非法图片时，直接在此 `SnackbarHostState` 上启动协程调用 `showSnackbar(reason)`，确保用户无需返回主页即可清晰感知错误原因。
- **备选考虑**：将整个 `App` 重构为单一全局 `Scaffold`。否决原因：`ScanScreen` 需要全屏深色沉浸式相机预览，全局 Scaffold 会引入不必要的内边距和重绘层级，局部挂载更轻量。

### 3. macOS 登录项 Binding 重构
- **决策**：将 `SettingsView.swift` 中的 `Toggle` 从 `@AppStorage` / `.onChange` 改为自定义 `Binding` 驱动，并显式处理 `.requiresApproval` 状态。
- **机制**：
  ```swift
  Toggle("登录时自动启动", isOn: Binding(
      get: { launchAtLogin },
      set: { setLoginItem($0) }
  ))
  ```
  在 `setLoginItem(enabled)` 抛出错误时，执行 `launchAtLogin = SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval`。若状态为 `.requiresApproval`，保持开关开启并提示用户在系统设置的「登录项」中批准。因为直接修改内部 `@State` 不会触发 `Binding.set`，所以彻底杜绝了错误回滚引发的递归 `.onChange` 调用，保证 `loginError` 稳定展示。

### 4. macOS 设置补全备份导入
- **决策**：在 `SettingsView.swift` 数据区添加“导入备份（JSON）”按钮，采用混合异步架构保证并发安全与 UI 流畅。
- **机制**：
  - 设置页维护 `importing` 状态，导入中按钮置灰禁用，防止连击重复入库。
  - 点击后在主线程使用 `NSOpenPanel` 限制类型为 `[.json]`。
  - 获取路径后派发至 `Task.detached` 异步读取大文件 UTF-8 文本并调用 `importBackupJson(text:)` 完成耗时的 CPU/IO 解析与校验。
  - 解析完成后切回 `@MainActor` 执行 `saveAccount` 遍历写入，确保 `accounts.json` 与钥匙串写入严格与全局主线程操作（添加、重命名、删除）串行化，彻底消除数据竞争。
  - 分别统计格式无效跳过条目与底层存储失败条目，在主线程使用 `NSAlert` 弹窗汇报导入结果（“成功导入 X 个账户，跳过 Y 个”）。
  - 若 `importBackupJson` 抛出 `CoreError.backupFormat`，显示格式错误提示。

### 5. Android 重命名拆分逻辑修正
- **决策**：移除 `AccountStore.rename` 中对 `displayTitle` 的调用，改为直接按首个空格拆分；并在 `Home.kt` 的重命名弹窗中使用 `account.rawName` 预填。
- **机制**：
  ```kotlin
  val parts = name.trim().split(" ", limit = 2)
  val siteName = parts[0]
  val username = if (parts.size > 1) parts[1] else ""
  database.accounts().save(current.copy(siteName = siteName, username = username))
  ```
  输入 `GitHub:work ada` 时，站点名为 `GitHub:work`，用户名为 `ada`，与 macOS 端 `Storage.swift` 的 `split(separator: " ", maxSplits: 1)` 行为完全对齐；弹窗预填原始名称，确保保存时不会因为 `displayTitle` 折叠而丢失冒号或重复词。

### 6. Android 数据库操作事务与文件 IO 异常捕获
- **决策**：
  - 在 `AccountStore.kt` 中使用 `database.withTransaction { ... }` 包裹 `save`（包含 `maxPosition()` 查询与自增）与 `delete`。
  - 在 `MainActivity.kt` 的相册选图 `reader.read(context, uri)`、`exportFile` 与 `importFile` 结果回调中加入 `try-catch (e: Exception)`，对文件读写权限、格式解析或存储空间耗尽等异常进行捕获，并通过 `message` 给出友好提示，避免进程 Crash。

## Risks / Trade-offs

- [Android 扫码锁定后若用户未成功保存] → 仅在确认返回前置锁定；若出现其他异常留在当前页，可允许返回重新扫描。
- [macOS 批量导入大量条目] → 读取文件与保存操作置于主线程之外（Task）执行，保持 UI 流畅。
