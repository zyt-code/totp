# Tasks

## 1. Verification

- [x] 1.1 确认状态项使用模板符号：`swift build --product TOTPApp` 通过，运行后辅助功能读到状态项名称对应 `lock.badge.clock`。
- [x] 1.2 确认激活策略切换：用真实控制器源码编译探针，验证 show 后为 `.regular`、close 后为 `.accessory`。
- [x] 1.3 运行 `swift test` 全绿，并运行 `./run.sh` 确认构建、签名、启动正常。
