# Tasks

## 1. Entry logic

- [x] 1.1 添加 `decodeBase32`。用 Swift Testing 断言带空格的完整 Base32 `GEZD GNBV GY3T QOJQ GEZD GNBV GY3T QOJQ` 解码为 ASCII `12345678901234567890`，并断言空值、非法字符和错误填充会失败。原 16 字符示例只对应前 10 字节，不能当作 20 字节种子。
- [x] 1.2 添加 `saveAccount`。用内存仓库断言有效表单同时写入元数据和 secret，空白网站名不写入，元数据失败时删除刚写入的 secret。

## 2. Form

- [x] 2.1 启用「新增」并打开录入窗口。默认 SHA-1、6 位、30 秒；算法含 SHA-256、SHA-512，位数含 8。保存成功后关闭窗口并重新加载列表，失败时保留窗口。确认 `swift build --product TOTPApp` 成功，且源码不引用 ScreenCaptureKit、Vision 或 CSV。

## 3. Integration

- [x] 3.1 运行 `swift test`，确认 Base32、保存和原有 RFC 测试都通过。
