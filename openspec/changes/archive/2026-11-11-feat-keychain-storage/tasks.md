# Tasks

## 1. Storage

- [x] 1.1 添加 `SecretStore`、`MemorySecretStore`、`AccountMetadata`、`AccountMetadataRepository` 和 `MemoryMetadataRepository`。用 Swift Testing 覆盖增查改删、缺失 id 和列表顺序，并断言元数据描述不含 secret。
- [x] 1.2 添加 `loadAccounts`：按元数据顺序组装，缺 secret 则跳过，显示名包含站点名和用户名。用内存假实现断言这三种结果。
- [x] 1.3 添加真实 Keychain secret store 和 JSON 元数据仓库。确认 `swift build` 成功；单元测试仍只使用内存假实现。

## 2. App source

- [x] 2.1 让 `TOTPApp` 从仓库加载账户，删除对 `MockAccounts.all` 的使用。空仓库显示现有空状态。确认 `swift build --product TOTPApp` 成功，且源码不引用 ScreenCaptureKit、Vision 或 CSV 解析。

## 3. Integration

- [x] 3.1 运行 `swift test`，确认存储测试和原有 RFC 测试都通过。
