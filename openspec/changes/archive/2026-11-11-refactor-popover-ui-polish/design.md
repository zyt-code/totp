# Design

## Context

`AccountList` 现在宽 240pt，空状态是一句文本，验证码只在悬停时出现。新增、设置和退出是菜单里的竖向按钮。计算、复制和存储已经可用。行为见本变更的规格。

## Goals / Non-Goals

**Goals:**

- 把现有弹窗换成固定尺寸的材质面板。
- 账户行始终显示验证码、徽章和倒计时。
- 底部操作收成一行，行为保持不变。

**Non-Goals:**

- 改 `TOTPCore`、Keychain、JSON 仓库、Base32 或录入表单字段。
- 搜索、分组、自定义图标、屏幕扫描、CSV。

## Decisions

### 1. 一个面板包住列表和工具栏

`MenuBarExtra` 的窗口内容改为一个 `VStack`：上面是列表，下面是工具栏。面板使用 `.regularMaterial`、连续圆角和 `strokeBorder`。宽度固定 300，高度至少 320。颜色只用 `primary`、`secondary` 和 `accentColor`，不写死黑白。

### 2. 空状态是视图，不是新流程

无账户时居中显示 `Image(systemName: "lock.badge.clock")`、标题、副标题和 `controlSize(.large)` 的胶囊按钮。按钮调用现有的打开录入窗口动作。它不调用 `saveAccount`。

### 3. 行内容拆开展示

账户名仍来自 `loadAccounts` 的 `"站点 用户名"`。视图按第一个空格拆成两行；没有用户名时只显示站点。徽章用站点名的首个可见字符。验证码始终用 `.monospacedDigit()`。悬停只切换该行的圆角背景。

环形倒计时继续调用现有 `remainingSeconds` 和 `ringFraction`。复制、2 秒「已复制」和 30 秒剪贴板清除继续留在 `AccountList`。

### 4. 工具栏替换竖向按钮

工具栏左侧用账户数量生成「共 X 个账户」。右侧三个 `plain` 按钮使用 `plus`、`gearshape` 和 `power`。设置按钮 `.disabled(true)`。悬停时按钮背景使用低透明度的系统填充色。

### 5. 屏幕录制和 CSV

本变更没有扫描或导入，所以没有权限流程，也没有 CSV 列。以后做扫描时再单独查屏幕录制权限；拒绝后不抓屏。

## Risks / Trade-offs

- [菜单窗口的系统边距可能让内容看起来不到 300pt] → 约束内容本身为 300pt，不尝试改系统窗口装饰。
- [验证码始终可见，肩窥风险比悬停显示更高] → 这是本次明确的界面要求；剪贴板清除行为不变。
- [账户名里的空格不只来自用户名分隔] → 只按第一个空格拆分，和现有 `"站点 用户名"` 格式一致。

## Migration Plan

无数据。回滚是恢复原来的 `AccountList` 和竖向按钮。

## Open Questions

无。
