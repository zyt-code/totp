# Tasks

## 1. Icon asset

- [x] 1.1 编写 `scripts/generate_icon.swift`：用 AppKit/CoreGraphics 逐尺寸绘制 16x16 到 512x512@2x 十张 PNG，经 `iconutil` 生成 `Resources/AppIcon.icns` 并删除临时 `.iconset`。运行一次脚本，确认 `Resources/AppIcon.icns` 存在、`iconutil -c iconset` 能拆回十张图，且 `.iconset` 目录已清理。

## 2. Packaging

- [x] 2.1 在 `run.sh` 中于拷贝图标前增加「缺失则调用生成脚本」分支，确认拷贝发生在 `codesign` 之前。删掉 `Resources/AppIcon.icns` 后运行 `./run.sh`，确认图标被重新生成、`Contents/Resources/AppIcon.icns` 存在、bundle plist 含 `CFBundleIconFile=AppIcon`，且签名仍为 `LocalDev`。

## 3. Verification

- [x] 3.1 运行 `./run.sh` 确认应用构建、签名并启动；确认进程存活且 `.app` 内含图标资源。
