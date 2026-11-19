//! 共享 TOTP 核心：算法、Base32、otpauth 解析、展示名称、备份。
//!
//! 行为以 `openspec/specs/totp-core/spec.md` 为准；本 crate 是它唯一的可执行实现。
//!
//! 注意 `panic = "abort"`：core 里的 panic 会终止宿主进程而不是抛异常（见 design.md 决定 12）。

uniffi::setup_scaffolding!();

mod backup;
mod base32;
mod model;
mod naming;
mod otp;
mod otpauth;

pub use model::*;

/// 解析一条 `otpauth://totp/` URI。
#[uniffi::export]
pub fn parse_otpauth_uri(uri: String) -> Result<ParsedAccount, CoreError> {
    otpauth::parse(&uri)
}

/// 账户卡片的标题与副标题。
#[uniffi::export]
pub fn display_title(site_name: String, account_name: String) -> DisplayTitle {
    naming::display(&site_name, &account_name)
}

/// 算一个账户在给定 Unix 时间点的验证码。
#[uniffi::export]
pub fn generate_code(account: AccountParams, unix_time: i64) -> Result<OtpCodeResult, CoreError> {
    otp::code_for(&account, unix_time)
}

/// 一次算完整个列表：每秒刷新只跨一次边界。
#[uniffi::export]
pub fn generate_codes_batch(accounts: Vec<AccountParams>, unix_time: i64) -> Vec<OtpCodeResult> {
    accounts
        .iter()
        .filter_map(|account| otp::code_for(account, unix_time).ok())
        .collect()
}

/// 手工录入用：Base32 文本 → 密钥字节。
#[uniffi::export]
pub fn decode_base32_secret(text: String) -> Result<Vec<u8>, CoreError> {
    base32::decode(&text)
}

/// 手工录入用：密钥字节 → Base32 文本（不含 padding，展示用）。
#[uniffi::export]
pub fn encode_base32_secret(secret: Vec<u8>) -> String {
    base32::encode(&secret)
}

/// 导出 JSON 备份文档。
#[uniffi::export]
pub fn export_backup_json(accounts: Vec<AccountParams>) -> Result<String, CoreError> {
    backup::export(&accounts)
}

/// 导入 JSON 备份文档；格式不对整体失败，单条账户非法计入 skipped。
#[uniffi::export]
pub fn import_backup_json(text: String) -> Result<BackupImport, CoreError> {
    backup::import(&text)
}
