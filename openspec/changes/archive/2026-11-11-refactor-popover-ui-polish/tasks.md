# Tasks

## 1. Popover

- [x] 1.1 把弹窗内容改为 300×至少 320 的材质面板。空状态显示图标、标题、副标题和「添加第一个账户」胶囊按钮，按钮只打开现有录入窗口。确认 `swift build --product TOTPApp` 成功。
- [x] 1.2 账户行显示首字母徽章、站点名、用户名、等宽验证码和环形倒计时。悬停只加圆角高亮；单击仍复制并显示「已复制」。底部改成「共 X 个账户」和 plus、禁用的 gear、power。确认源码不改 `TOTPCore`，也不引用 ScreenCaptureKit、Vision 或 CSV。

## 2. Verification

- [x] 2.1 运行 `swift test`，确认原有计算、存储和录入测试仍通过。
