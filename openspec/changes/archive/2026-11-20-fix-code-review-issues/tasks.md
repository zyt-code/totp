# Tasks

## 1. Android 扫码与账户交互修复

- [x] 1.1 在 `ScanScreen.kt` 中添加 `isProcessing` 防重入标志，捕获到有效二维码后立即阻断后续视频流帧的处理，避免重复入库
- [x] 1.2 在 `ScanScreen.kt` 布局内挂载专用的 `SnackbarHost`，并接通相册选图失败与无效二维码的错误事件，使其在扫码界面即时显示 Snackbar 提示
- [x] 1.3 修正 `AccountStore.kt` 的 `rename` 方法，严格按首个空格拆分站点名与用户名，在 `Home.kt` 中使用 `rawName` 预填重命名弹窗，并在 `DisplayTest.kt`（JVM 单测）与 `AccountStoreTest.kt` 增加包含冒号与重复 token 的重命名用例验证行为

## 2. Android 存储事务与 IO 异常防护

- [x] 2.1 在 `AccountStore.kt` 中使用 `database.withTransaction` 包裹 `save` 与 `delete` 操作，确保元数据与密文的原子一致性
- [x] 2.2 在 `MainActivity.kt` 的 `exportFile` 与 `importFile` 结果回调中添加 `try-catch` 异常捕获，并在发生 IO 错误或权限失效时通过友好提示反馈给用户

## 3. macOS 设置响应与备份导入补全

- [x] 3.1 在 `SettingsView.swift` 中将“登录时自动启动”开关改用自定义 `Binding` 驱动，彻底消除注册失败时 `.onChange` 循环重置引发的错误信息被抹除问题
- [x] 3.2 在 `SettingsView.swift` 数据区添加“导入备份（JSON）”功能，调起 `NSOpenPanel` 读取 `.json` 并调用 `importBackupJson` 恢复账户，通过 `NSAlert` 展示导入统计
- [x] 3.3 移除 `MacOS/Tests/TOTPCoreTests/AccountManagementTests.swift` 第 20 行多余的 `try` 关键字，消除 Swift 6 编译器警告

## 4. 规格验证与回归测试

- [x] 4.1 运行 `(cd core && cargo test)` 与 `(cd MacOS && swift test)`，验证 Rust Core 与 macOS 测试套件全部绿灯且无编译警告
- [x] 4.2 运行 `(cd Android && ./gradlew test)`，验证 Android JVM 单测全部通过
- [x] 4.3 运行 `openspec validate --all`，验证全局及变更增量规格校验完全合规
