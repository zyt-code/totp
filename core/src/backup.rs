use serde::{Deserialize, Serialize};

use crate::model::{AccountParams, BackupImport, CoreError, HashAlgorithm, ParsedAccount};

const FORMAT: &str = "totp-backup";
const VERSION: u32 = 2;

#[derive(Serialize, Deserialize)]
struct Document {
    format: String,
    version: u32,
    accounts: Vec<Entry>,
}

#[derive(Serialize, Deserialize)]
struct Entry {
    site_name: String,
    account_name: String,
    secret: String,
    algorithm: String,
    digits: i32,
    period: i32,
}

pub(crate) fn export(accounts: &[AccountParams]) -> Result<String, CoreError> {
    let document = Document {
        format: FORMAT.to_string(),
        version: VERSION,
        accounts: accounts
            .iter()
            .map(|account| Entry {
                site_name: account.issuer.clone(),
                account_name: account.account_name.clone(),
                secret: crate::base32::encode(&account.secret),
                algorithm: account.algorithm.name().to_string(),
                digits: account.digits,
                period: account.period,
            })
            .collect(),
    };
    serde_json::to_string_pretty(&document).map_err(|error| CoreError::BackupFormat(error.to_string()))
}

pub(crate) fn import(text: &str) -> Result<BackupImport, CoreError> {
    let document: Document = serde_json::from_str(text).map_err(|_| {
        CoreError::BackupFormat(
            "不是 2.0 的 JSON 备份：需要 format=totp-backup、version=2 的 JSON 文件".into(),
        )
    })?;
    if document.format != FORMAT || document.version != VERSION {
        return Err(CoreError::BackupFormat(format!(
            "不支持的备份格式：format={}、version={}（期望 format={FORMAT}、version={VERSION}）",
            document.format, document.version
        )));
    }

    let mut accounts = Vec::with_capacity(document.accounts.len());
    let mut skipped = 0i32;
    for entry in document.accounts {
        match accepted(entry) {
            Some(account) => accounts.push(account),
            None => skipped += 1,
        }
    }
    Ok(BackupImport { accounts, skipped })
}

fn accepted(entry: Entry) -> Option<ParsedAccount> {
    let algorithm = HashAlgorithm::parse(&entry.algorithm)?;
    if entry.digits != 6 && entry.digits != 8 {
        return None;
    }
    if entry.period < 1 {
        return None;
    }
    let secret = crate::base32::decode(&entry.secret).ok()?;
    Some(ParsedAccount {
        issuer: entry.site_name,
        account_name: entry.account_name,
        secret,
        algorithm,
        digits: entry.digits,
        period: entry.period,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample(id: &str, issuer: &str, account_name: &str) -> AccountParams {
        AccountParams {
            id: id.into(),
            issuer: issuer.into(),
            account_name: account_name.into(),
            secret: b"12345678901234567890".to_vec(),
            algorithm: HashAlgorithm::Sha256,
            digits: 8,
            period: 45,
        }
    }

    #[test]
    fn exported_document_shape() {
        let json = export(&[sample("1", "GitHub", "ada"), sample("2", "Acme", "")]).unwrap();
        let value: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert_eq!(value["format"], "totp-backup");
        assert_eq!(value["version"], 2);
        assert_eq!(value["accounts"].as_array().unwrap().len(), 2);
        assert_eq!(value["accounts"][0]["secret"], "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ");
        assert_eq!(value["accounts"][0]["algorithm"], "SHA256");
    }

    #[test]
    fn round_trip_restores_every_field() {
        let accounts = vec![sample("1", "GitHub", "ada"), sample("2", "阿里云", "")];
        let imported = import(&export(&accounts).unwrap()).unwrap();
        assert_eq!(imported.skipped, 0);
        assert_eq!(imported.accounts.len(), 2);
        for (original, restored) in accounts.iter().zip(imported.accounts.iter()) {
            assert_eq!(&original.issuer, &restored.issuer);
            assert_eq!(&original.account_name, &restored.account_name);
            assert_eq!(&original.secret, &restored.secret);
            assert_eq!(original.algorithm, restored.algorithm);
            assert_eq!(original.digits, restored.digits);
            assert_eq!(original.period, restored.period);
        }
    }

    #[test]
    fn unknown_version_is_rejected() {
        let json = r#"{"format":"totp-backup","version":1,"accounts":[]}"#;
        let error = import(json).unwrap_err();
        assert!(matches!(error, CoreError::BackupFormat(_)));
    }

    #[test]
    fn line_per_uri_text_is_rejected() {
        let error = import("otpauth://totp/ada?secret=GEZDGNBVGY3TQOJQ\n").unwrap_err();
        assert!(matches!(error, CoreError::BackupFormat(_)));
    }

    #[test]
    fn missing_accounts_array_is_rejected() {
        assert!(import(r#"{"format":"totp-backup","version":2}"#).is_err());
    }

    #[test]
    fn invalid_account_is_skipped() {
        let json = r#"{
          "format": "totp-backup",
          "version": 2,
          "accounts": [
            {"site_name":"A","account_name":"a","secret":"GEZDGNBVGY3TQOJQ","algorithm":"SHA1","digits":6,"period":30},
            {"site_name":"B","account_name":"b","secret":"GEZD1","algorithm":"SHA1","digits":6,"period":30}
          ]
        }"#;
        let imported = import(json).unwrap();
        assert_eq!(imported.accounts.len(), 1);
        assert_eq!(imported.skipped, 1);
    }

    #[test]
    fn unsupported_parameters_are_skipped() {
        let json = r#"{
          "format": "totp-backup",
          "version": 2,
          "accounts": [
            {"site_name":"A","account_name":"a","secret":"GEZDGNBVGY3TQOJQ","algorithm":"SHA384","digits":6,"period":30},
            {"site_name":"B","account_name":"b","secret":"GEZDGNBVGY3TQOJQ","algorithm":"SHA1","digits":7,"period":30},
            {"site_name":"C","account_name":"c","secret":"GEZDGNBVGY3TQOJQ","algorithm":"SHA1","digits":6,"period":0}
          ]
        }"#;
        let imported = import(json).unwrap();
        assert_eq!(imported.accounts.len(), 0);
        assert_eq!(imported.skipped, 3);
    }
}
