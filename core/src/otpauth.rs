#[cfg(test)]
use percent_encoding::{AsciiSet, NON_ALPHANUMERIC, utf8_percent_encode};
use url::Url;

use crate::model::{CoreError, HashAlgorithm, ParsedAccount};

/// 只保留 RFC 3986 的 unreserved，其余全部百分号编码；空格是 `%20` 而不是 `+`。
#[cfg(test)]
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
    // 表单编码把 `+` 当空格（design 决定 11）：issuer 等字段沿用；secret 例外，`+` 不是 Base32 字符，
    // 先把 `+` 转成 %2B 再解析，让密钥拿到原样 `+` 交给 Base32 拒绝
    let query = url.query().unwrap_or_default().replace('+', "%2B");
    for (key, value) in url::form_urlencoded::parse(query.as_bytes()) {
        let key = key.as_ref();
        let value = match key {
            "secret" => value.into_owned(),
            _ => value.replace('+', " "),
        };
        match key {
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

/// 仅测试用：生成 otpauth URI 供 round-trip 测试。
#[cfg(test)]
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

#[cfg(test)]
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

    #[test]
    fn rejects_plus_in_secret_instead_of_treating_it_as_space() {
        // `+` 不是 Base32 字符；若当空格忽略，"JBSW Y3DP" 会被静默接受成另一把密钥
        assert!(matches!(
            parse("otpauth://totp/ada?secret=JBSW+Y3DP"),
            Err(CoreError::InvalidSecret)
        ));
        // 百分号编码的 `+` 走同一条路径，也必须原样拒绝
        assert!(matches!(
            parse("otpauth://totp/ada?secret=JBSW%2BY3DP"),
            Err(CoreError::InvalidSecret)
        ));
    }
}
