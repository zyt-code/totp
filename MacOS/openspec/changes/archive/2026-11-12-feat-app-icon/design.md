# Design

## Context

`run.sh` 已经会在 `Resources/AppIcon.icns` 存在时把它拷进 bundle，并在生成的 bundle `Info.plist` 里声明 `CFBundleIconFile=AppIcon`。缺的是图标本身和生成脚本。行为见本变更的规格。

## Goals / Non-Goals

**Goals:**

- 用系统框架矢量绘制图标，按目标像素尺寸逐个渲染，小尺寸不糊。
- 一次生成后把 `.icns` 提交进仓库，无脚本环境也能打包。
- 打包时缺图标自动补生成，且在签名之前完成。

**Non-Goals:**

- 图标设置界面、多套主题图标、深色/浅色两版。
- 改 SwiftPM 的 `Sources/TOTPApp/Info.plist`（它不参与最终 bundle plist）。
- 引入第三方绘图或图标依赖。

## Decisions

### 1. 逐尺寸矢量渲染而不是缩放大图

`drawIcon(in:size:)` 用相对画布的比例绘制所有元素，每个目标尺寸都以该尺寸的像素大小重新渲染。避免 1024 缩到 16 时的模糊与锯齿。

### 2. 形状与留白

画布 1024，主图区域 824 正方形居中（左右上下各留 100），圆角半径取 824 × 0.225 ≈ 185。用 `CGPath(roundedRect:)` 近似 macOS 连续圆角。

### 3. 配色（一处假设）

主背景用垂直渐变 `#1E293B`（顶）→ `#0F172A`（底），再叠一层 `#1D4ED8`/`#2563EB` 的柔和径向高光，让蓝色更「有光」而不是死板双色。原描述里四个色值分两组，这里按「底色渐变 + 蓝色高光」理解。

描边：1.5px 半透明白色（在 1024 画布上按比例换算），底部加柔和投影。

### 4. 前景图形

白色挂锁：锁体为圆角矩形，锁梁为上半圆弧。外圈一道带缺口的进度环，线宽约为画布 4%，`lineCap = .round`，从 -90° 起留出约 60° 缺口，呼应 30 秒倒计时。

### 5. 输出与清理

脚本写到 `Resources/AppIcon.iconset` 的十张标准倍图，调用系统 `iconutil -c icns`，成功后删除整个 `.iconset` 目录。`iconutil` 失败时脚本以非零状态退出，打包脚本因此中止，不会签出无图标的包。

### 6. 打包顺序

`run.sh` 先检查 `Resources/AppIcon.icns`，缺失则运行 `swift scripts/generate_icon.swift`；随后拷进 `Contents/Resources`；最后才 `codesign`。签名覆盖图标资源，顺序不能颠倒。

## Risks / Trade-offs

- [逐尺寸渲染代码更啰嗦] → 换取 16/32 尺寸的清晰度，图标只在打包时生成。
- [仓库里提交二进制 `.icns`] → 体积约几十 KB；换来无网络、无脚本依赖可打包。
- [四色渐变的原始意图不确定] → 已按底色渐变加蓝色高光实现，若与预期不符只需改 `drawIcon` 的渐变定义。

## Migration Plan

无数据迁移。回滚是删除 `Resources/AppIcon.icns` 与 `scripts/generate_icon.swift`，并移除 `run.sh` 的生成分支。

## Open Questions

无。
