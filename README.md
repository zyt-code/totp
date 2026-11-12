# totp

跨平台 TOTP（时间型一次性密码）认证器。当前已实现 macOS 菜单栏版本，Android 为预留目录。

## 目录结构

```
MacOS/    macOS 14+ 菜单栏应用（Swift Package）
Android/  预留，尚未实现
```

## 功能（macOS）

- 常驻菜单栏，无 Dock 图标；点击状态项弹出账户列表
- 每行显示验证码、剩余秒数环形倒计时；剩余 ≤5 秒转为警示色
- 悬停高亮，单击整行复制验证码（复制后按偏好自动清空剪贴板）
- 右键可复制账号名、重命名、删除账户
- 新增账户：手动录入、粘贴 `otpauth://` 自动填充、屏幕二维码识别
- 设置：登录时启动、剪贴板自动清理与延迟、验证码分段显示、导出 otpauth 备份
- 支持 SHA-1 / SHA-256 / SHA-512，6 位或 8 位，自定义周期

## 构建与运行

```bash
cd MacOS
./run.sh
```

`run.sh` 会编译、组装 `.app`、签名并启动。签名优先使用钥匙串中名为 `LocalDev` 的代码签名证书；不存在时降级为 ad-hoc 签名（会重复触发钥匙串授权弹窗）。

首次需要屏幕识别时，系统会要求授予「屏幕录制」权限，授权后需重新打开应用。

## 安全设计

- Secret 只存 macOS Keychain，元数据另存本地 JSON，不含密钥
- 完全离线：无后端、无网络请求、无第三方埋点
- 复制验证码后可按设置延时清空剪贴板，且仅在内容未被替换时清理

## 规格与变更流程

项目使用 [OpenSpec](https://github.com/Fission-AI/OpenSpec) 管理规格，规格根目录在 `MacOS/openspec`：

```bash
cd MacOS
openspec list
openspec validate --specs --strict
```

## 环境要求

- macOS 14 或更高
- Swift 5.10+ / Swift 6（Xcode 命令行工具）
