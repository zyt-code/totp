use std::fmt;

/// HMAC 哈希算法，取值与 `otpauth://` 的 `algorithm` 参数一致。
#[derive(uniffi::Enum, Clone, Copy, Debug, PartialEq, Eq)]
pub enum HashAlgorithm {
    Sha1,
    Sha256,
    Sha512,
}

impl HashAlgorithm {
    pub(crate) fn name(self) -> &'static str {
        match self {
            HashAlgorithm::Sha1 => "SHA1",
            HashAlgorithm::Sha256 => "SHA256",
            HashAlgorithm::Sha512 => "SHA512",
        }
    }

    pub(crate) fn parse(value: &str) -> Option<Self> {
        match value.to_ascii_uppercase().as_str() {
            "SHA1" => Some(HashAlgorithm::Sha1),
            "SHA256" => Some(HashAlgorithm::Sha256),
            "SHA512" => Some(HashAlgorithm::Sha512),
            _ => None,
        }
    }
}

/// 带 id 的账户，用于算码与导出。
#[derive(uniffi::Record, Clone)]
pub struct AccountParams {
    pub id: String,
    pub issuer: String,
    pub account_name: String,
    pub secret: Vec<u8>,
    pub algorithm: HashAlgorithm,
    pub digits: i32,
    pub period: i32,
}

/// 解析结果：没有 id，由宿主生成。
#[derive(uniffi::Record, Clone, PartialEq, Eq)]
pub struct ParsedAccount {
    pub issuer: String,
    pub account_name: String,
    pub secret: Vec<u8>,
    pub algorithm: HashAlgorithm,
    pub digits: i32,
    pub period: i32,
}

#[derive(uniffi::Record, Clone, Debug, PartialEq, Eq)]
pub struct DisplayTitle {
    pub title: String,
    pub subtitle: Option<String>,
}

#[derive(uniffi::Record, Clone, Debug, PartialEq, Eq)]
pub struct OtpCodeResult {
    pub id: String,
    pub code: String,
    pub remaining_seconds: i32,
    pub period: i32,
}

#[derive(uniffi::Record, Clone)]
pub struct BackupImport {
    pub accounts: Vec<ParsedAccount>,
    pub skipped: i32,
}

/// 密钥不得进入文本：`Secret material stays out of text` 要求这些类型的文本形式不含密钥。
macro_rules! redacted_debug {
    ($ty:ty, $($field:ident),*) => {
        impl fmt::Debug for $ty {
            fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
                f.debug_struct(stringify!($ty))
                    $(.field(stringify!($field), &self.$field))*
                    .field("secret", &"<redacted>")
                    .finish()
            }
        }
    };
}

redacted_debug!(AccountParams, id, issuer, account_name, algorithm, digits, period);
redacted_debug!(ParsedAccount, issuer, account_name, algorithm, digits, period);

impl fmt::Debug for BackupImport {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("BackupImport")
            .field("accounts", &self.accounts)
            .field("skipped", &self.skipped)
            .finish()
    }
}

#[derive(uniffi::Error, thiserror::Error, Debug, PartialEq, Eq)]
pub enum CoreError {
    #[error("invalid secret")]
    InvalidSecret,
    #[error("invalid otpauth URI: {0}")]
    InvalidUri(String),
    #[error("unsupported parameter: {0}")]
    UnsupportedParam(String),
    #[error("{0}")]
    BackupFormat(String),
}

#[cfg(test)]
mod tests {
    use super::*;

    fn account() -> AccountParams {
        AccountParams {
            id: "1".into(),
            issuer: "GitHub".into(),
            account_name: "ada".into(),
            secret: b"12345678901234567890".to_vec(),
            algorithm: HashAlgorithm::Sha1,
            digits: 6,
            period: 30,
        }
    }

    fn parsed() -> ParsedAccount {
        ParsedAccount {
            issuer: "GitHub".into(),
            account_name: "ada".into(),
            secret: b"12345678901234567890".to_vec(),
            algorithm: HashAlgorithm::Sha1,
            digits: 6,
            period: 30,
        }
    }

    #[test]
    fn account_debug_omits_secret() {
        let rendered = format!("{:?}", account());
        assert!(rendered.contains("<redacted>"));
        assert!(!rendered.contains("12345678901234567890"));
        assert!(!rendered.contains("GEZDGNBVGY3TQOJQ"));
        assert!(!rendered.contains("3132333435"));
    }

    #[test]
    fn parsed_account_debug_omits_secret() {
        let rendered = format!("{:?}", parsed());
        assert!(rendered.contains("<redacted>"));
        assert!(!rendered.contains("12345678901234567890"));
        assert!(!rendered.contains("GEZDGNBVGY3TQOJQ"));
    }

    #[test]
    fn backup_import_debug_omits_secret() {
        let rendered = format!(
            "{:?}",
            BackupImport {
                accounts: vec![parsed()],
                skipped: 0
            }
        );
        assert!(!rendered.contains("12345678901234567890"));
        assert!(!rendered.contains("GEZDGNBVGY3TQOJQ"));
    }
}
