# Tasks

## 1. 构建与工具链

- [x] 1.1 `build-macos.sh` / `build-android.sh` 显式 `cargo build --release --bin uniffi-bindgen` 并校验可执行。验证：清空 `core/target` 后两个脚本从零跑通。
- [x] 1.2 `build-android.sh` 直接使用 `ANDROID_NDK_HOME`；值为版本父目录时取最新子目录；未设置时取 `$ANDROID_HOME/ndk` 最新版；校验 `source.properties`/`toolchains`。验证：三种路径均跑到 `libtotp_core.so`，缺 NDK 报可读错误。
- [x] 1.3 16 KB 页对齐与体积预算保持。验证：`llvm-readelf -l` 最小 LOAD 对齐 16384，so 718400 字节。

## 2. 数据与解析边界

- [x] 2.1 备份导入先解析外层信封，再逐条解析 Entry，坏条目计入 skipped。验证：`malformed_account_is_skipped` 等 cargo 用例。
- [x] 2.2 `otpauth` 的 `+`→空格只作用于非 secret 字段；`secret` 保留 `+` 交由 Base32 拒绝。验证：`JBSW+Y3DP` 与 `JBSW%2BY3DP` 都返回 `InvalidSecret`。
- [x] 2.3 移除 `format_otpauth_uri` FFI 导出，formatter 改为 `#[cfg(test)]`。验证：生成的 Swift/Kotlin 绑定无 `formatOtpauthUri`。

## 3. 展示与规格

- [x] 3.1 `naming::display` 对存储账户名折叠重复 token，spec 增加 stored 场景。验证：`stored_repeated_account_token_collapses`。
- [x] 3.2 Base32 规格增加 `+` 拒绝场景，注释说明表单编码例外范围。验证：`openspec validate --all` 与 `cargo test`。

## 4. 收口验证

- [x] 4.1 `cargo test` 39/39；`swift test` 16/16；Android `:app:testDebugUnitTest` 通过。
- [x] 4.2 清空生成产物后重跑双端 core 构建；`openspec validate --all` 18/18。
