# Design

## Context

`MenuBarExtra` 用 `systemImage: "lock"`，状态项是彩色无关的 SF Symbol，但和主图标视觉不呼应。`AddAccountWindowController.show()` 会把 `NSApp.setActivationPolicy(.regular)`，此前没有任何地方恢复它。

## Goals / Non-Goals

**Goals:**

- 状态项与主图标同一套符号语言。
- 关闭编辑窗口后立刻回到纯菜单栏形态。
- 打包脚本重启稳定。

**Non-Goals:**

- 自绘 18×18 位图状态项。
- 改变「打开窗口时切成 regular」这一前提。

## Decisions

### 1. 用 SF Symbol 而不是自绘位图

`MenuBarExtra("TOTP", systemImage: "lock.badge.clock")` 交给系统渲染，SF Symbol 本身按模板处理，菜单栏明暗自动反色，不需要手工设 `isTemplate`。自绘位图要额外处理高亮态、明暗和 Retina，收益不抵成本。

### 2. 在 windowWillClose 统一恢复策略

`AddAccountWindowController` 实现 `NSWindowDelegate`，在 `windowWillClose` 里判断除自身外是否还有可见、可成为主窗口的非面板窗口；没有就 `NSApp.setActivationPolicy(.accessory)`。

排除 `NSPanel` 是为了不把 `MenuBarExtra` 的弹窗面板算成编辑窗口。取消、保存成功、Esc、红叉最终都走 `NSWindow.close()`，因此一处回调覆盖全部路径。

### 3. 重启等待旧进程退出

`run.sh` 在 `pkill` 后轮询 `pgrep` 直到进程消失再 `open`，消除 `error -600`。

## Risks / Trade-offs

- [`.regular` 与 `.accessory` 来回切换，Dock 图标会闪一下] → 这是无 Dock 应用临时获取键盘焦点必须付出的代价。
- [若将来出现第二个编辑窗口，关闭其一不应恢复 accessory] → 判断已按「仍有可见编辑窗口」处理。

## Migration Plan

无数据迁移。回滚是恢复 `systemImage: "lock"` 并移除 `NSWindowDelegate` 扩展。

## Open Questions

无。
