use percent_encoding::{AsciiSet, NON_ALPHANUMERIC, utf8_percent_encode};
use url::Url;

use crate::model::{CoreError, HashAlgorithm, ParsedAccount};

/// 只保留 RFC 3986 的 unreserved，其余全部百分号编码；空格是 `%20` 而不是 `+`。
const ESCAPE: &AsciiSet = &NON_ALPHANUMERIC
    .remove(b'-')
    .remove(b'.')
    .remove(b'_')
    .remove(b'~');

pub(crate) fn parse(text: &str) -> Result<ParsedAccount, CoreError> {
    let url = Url::parse(text).map_err(|error| CoreError::InvalidUri(error.to_string()))?;
    if url.scheme() != "otpauth" || url.host_str() != Some("totp") {
        return Err(CoreError::InvalidUri("not otpauth://totp".into()));
    }

    let mut secret: Option<String> = None;
    let mut issuer: Option<String> = None;
    let mut algorithm = HashAlgorithm::Sha1;
    let mut digits = 6i32;
    let mut period = 30i32;
    for (key, value) in url.query_pairs() {
        // 保留两端既有行为：query 里的 `+` 当空格（design 决定 11）
        let value = value.replace('+', " ");
        match key.as_ref() {
            "secret" => secret = Some(value),
            "issuer" => issuer = non_empty(value.trim()),
            "algorithm" => {
                algorithm = HashAlgorithm::parse(&value).ok_or_else(|| {
                    CoreError::UnsupportedParam(format!("algorithm {value}"))
                })?
            }
            "digits" => {
                digits = match value.trim() {
                    "6" => 6,
                    "8" => 8,
                    other => {
                        return Err(CoreError::UnsupportedParam(format!("digits {other}")));
                    }
                }
            }
            "period" => {
                period = value
                    .trim()
                    .parse::<i32>()
                    .ok()
                    .filter(|period| *period >= 1)
                    .ok_or_else(|| CoreError::UnsupportedParam(format!("period {value}")))?
            }
            _ => {}
        }
    }

    let secret = secret
        .filter(|secret| !secret.is_empty())
        .ok_or(CoreError::InvalidSecret)?;

    let label = percent_encoding::percent_decode_str(url.path().trim_matches('/'))
        .decode_utf8()
        .map_err(|error| CoreError::InvalidUri(error.to_string()))?;
    let mut parts = label.splitn(2, ':').map(|part| part.trim().to_string());
    let first = parts.next().unwrap_or_default();
    let second = parts.next();
    let account_name = match &second {
        Some(account) => account.clone(),
        None => first.clone(),
    };
    let label_issuer = if second.is_some() {
        non_empty(first.as_str())
    } else {
        None
    };

    Ok(ParsedAccount {
        issuer: issuer.or(label_issuer).unwrap_or_default(),
        account_name,
        secret: crate::base32::decode(&secret)?,
        algorithm,
        digits,
        period,
    })
}

pub(crate) fn format(account: &ParsedAccount) -> String {
    let label = if account.account_name.is_empty() {
        escape(&account.issuer)
    } else {
        format!(
            "{}:{}",
            escape(&account.issuer),
            escape(&account.account_name)
        )
    };
    format!(
        "otpauth://totp/{label}?secret={}&issuer={}&algorithm={}&digits={}&period={}",
        crate::base32::encode(&account.secret),
        escape(&account.issuer),
        account.algorithm.name(),
        account.digits,
        account.period,
    )
}

fn escape(text: &str) -> String {
    utf8_percent_encode(text, ESCAPE).to_string()
}

fn non_empty(text: &str) -> Option<String> {
    (!text.is_empty()).then(|| text.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_full_uri() {
        let parsed = parse(
            "otpauth://totp/GitHub:ada?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=GitHub&algorithm=SHA256&digits=8&period=45",
        )
        .unwrap();
        assert_eq!(parsed.issuer, "GitHub");
        assert_eq!(parsed.account_name, "ada");
        assert_eq!(parsed.secret, b"12345678901234567890");
        assert_eq!(parsed.algorithm, HashAlgorithm::Sha256);
        assert_eq!(parsed.digits, 8);
        assert_eq!(parsed.period, 45);
    }

    #[test]
    fn applies_defaults() {
        let parsed =
            parse("otpauth://totp/ada?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ").unwrap();
        assert_eq!(parsed.issuer, "");
        assert_eq!(parsed.account_name, "ada");
        assert_eq!(parsed.algorithm, HashAlgorithm::Sha1);
        assert_eq!(parsed.digits, 6);
        assert_eq!(parsed.period, 30);
    }

    #[test]
    fn label_issuer_is_used_when_query_issuer_absent() {
        let parsed =
            parse("otpauth://totp/GitHub:ada?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ").unwrap();
        assert_eq!(parsed.issuer, "GitHub");
        assert_eq!(parsed.account_name, "ada");
    }

    #[test]
    fn rejects_unsupported_values() {
        assert!(parse("otpauth://hotp/ada?secret=AAAA").is_err());
        assert!(parse("otpauth://totp/ada").is_err());
        assert!(parse("otpauth://totp/ada?secret=AAAA&algorithm=SHA384").is_err());
        assert!(parse("otpauth://totp/ada?secret=AAAA&digits=7").is_err());
        assert!(parse("otpauth://totp/ada?secret=AAAA&period=0").is_err());
        assert!(parse("https://example.com/?secret=AAAA").is_err());
    }

    #[test]
    fn plus_in_issuer_becomes_space() {
        let parsed =
            parse("otpauth://totp/x?secret=GEZDGNBVGY3TQOJQ&issuer=Acme+Inc").unwrap();
        assert_eq!(parsed.issuer, "Acme Inc");
    }

    #[test]
    fn decodes_plus_in_issuer_and_percent_encoded_label() {
        let parsed = parse(
            "otpauth://totp/Spot%20Auth%20Lab:test%40spot-auth.app?secret=GEZDGNBV&issuer=Spot+Auth+Lab",
        )
        .unwrap();
        assert_eq!(parsed.issuer, "Spot Auth Lab");
        assert_eq!(parsed.account_name, "test@spot-auth.app");
    }

    #[test]
    fn round_trips_chinese_and_spaces() {
        let account = ParsedAccount {
            issuer: "阿里云 云盾".into(),
            account_name: "ada@example.com".into(),
            secret: b"12345678901234567890".to_vec(),
            algorithm: HashAlgorithm::Sha512,
            digits: 8,
            period: 60,
        };
        let uri = format(&account);
        assert!(!uri.contains(' '), "空格必须编码为 %20: {uri}");
        assert_eq!(parse(&uri).unwrap(), account);
    }

    #[test]
    fn empty_account_name_writes_label_without_colon() {
        let account = ParsedAccount {
            issuer: "Acme".into(),
            account_name: String::new(),
            secret: b"12345678901234567890".to_vec(),
            algorithm: HashAlgorithm::Sha1,
            digits: 6,
            period: 30,
        };
        let uri = format(&account);
        assert!(uri.starts_with("otpauth://totp/Acme?secret="));
        // URI 格式无法区分「无账户名」与「账户名等于 issuer」，解析会把 label 读成账户名；
        // 规格的往返要求只覆盖 secret/algorithm/digits/period（备份走 JSON 才保留名称）。
        let parsed = parse(&uri).unwrap();
        assert_eq!(parsed.issuer, "Acme");
        assert_eq!(parsed.account_name, "Acme");
        assert_eq!(parsed.secret, account.secret);
        assert_eq!(parsed.algorithm, account.algorithm);
        assert_eq!(parsed.digits, account.digits);
        assert_eq!(parsed.period, account.period);
    }

    #[test]
    fn rejects_secret_outside_base32() {
        assert!(parse("otpauth://totp/ada?secret=GEZD1").is_err());
    }
}
