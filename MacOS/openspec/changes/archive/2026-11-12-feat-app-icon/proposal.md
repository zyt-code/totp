# Proposal

## Why

应用目前没有图标文件。打包出的 `.app` 在 Finder 和系统弹窗里显示通用空白图标，和菜单栏工具的定位不符。

## What Changes

- 新增 `scripts/generate_icon.swift`：用 AppKit / CoreGraphics 矢量绘制 1024px 母图，导出 `AppIcon.iconset` 全套 10 张倍图，调用 `iconutil` 生成 `Resources/AppIcon.icns`，随后删除临时目录。
- 图标视觉：824px 圆角矩形主区域、深蓝垂直渐变、内高光描边与柔和投影，中央白色挂锁加带缺口的进度环。
- 生成一次 `Resources/AppIcon.icns` 并纳入仓库，保证没有脚本环境时也能打包出图标。
- `run.sh` 在 `Resources/AppIcon.icns` 缺失时自动调用生成脚本，并在固定证书签名之前把图标拷进 bundle 的 `Contents/Resources`。
- bundle 的 `Info.plist` 继续声明 `CFBundleIconFile` 为 `AppIcon`。
- 不改 TOTP 计算、存储、列表和录入流程。`Sources/TOTPApp/Info.plist`（SwiftPM 资源）不参与最终 bundle plist，保持现状。

## Capabilities

### New Capabilities

- `app-icon`: 应用包内包含可用的 `.icns` 图标，并在缺失时由构建脚本自动生成。

### Modified Capabilities

- 无。

## Impact

- 新增 `scripts/generate_icon.swift` 与 `Resources/AppIcon.icns`。
- `run.sh` 增加图标自动生成与拷贝步骤。
- 不引入第三方依赖，绘制只用系统框架。
