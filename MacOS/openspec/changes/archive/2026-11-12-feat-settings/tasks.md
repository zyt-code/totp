# Tasks

## 1. Core helpers

- [x] 1.1 添加 `shouldClearClipboard` 与带 `grouped` 参数的 `formattedCode`。用 Swift Testing 覆盖内容相同、内容被替换、剪贴板为空，以及分段开/关两种显示。
- [x] 1.2 添加 `encodeBase32`、`otpauthURI(for:)`、`otpauthBackup(accounts:)`。用测试断言编码后再由 `parseOtpauth` 解析得到相同的 secret、算法、位数与周期，且多账户按行分隔。

## 2. Settings window

- [x] 2.1 抽出 `restoreMenuBarOnlyIfNoEditors(excluding:)` 并让新增窗口改用它，行为不变。
- [x] 2.2 新增 `SettingsWindowController` 与设置视图（宽 440、`.formStyle(.grouped)`、Esc 关闭），启用齿轮按钮并接线。确认打开后 `.regular`、关闭后回到 `.accessory`。

## 3. Settings items

- [x] 3.1 接入三个 `@AppStorage` 偏好：登录启动（`SMAppService`，含状态同步与失败提示）、剪贴板开关与延迟（15/30/60）、验证码分段显示。
- [x] 3.2 让列表读取偏好：分段显示开关生效，复制后的清理按开关与延迟执行。确认复制进剪贴板的内容始终无空格。
- [x] 3.3 添加导出备份按钮：确认后经保存面板写出换行分隔的 otpauth 文本；底部显示应用名、`v1.0.0` 与存储状态行。

## 4. Verification

- [x] 4.1 把账户加载从 `.task` 移到启动时，消除弹窗首帧空态闪烁。确认 app 内加载路径返回 `records=3 / accounts=3`，且首帧即显示已保存账户。
- [x] 4.2 运行 `swift test` 全绿，`swift build --product TOTPApp` 通过。
- [x] 4.3 运行 `./run.sh`，确认设置窗口可打开、各项可切换，关闭后 Dock 图标消失。
