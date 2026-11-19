use hmac::{Hmac, Mac};
use sha1::Sha1;
use sha2::{Sha256, Sha512};

use crate::model::{AccountParams, CoreError, HashAlgorithm, OtpCodeResult};

macro_rules! hmac_digest {
    ($hash:ty, $secret:expr, $message:expr) => {{
        let mut mac = <Hmac<$hash> as Mac>::new_from_slice($secret).expect("HMAC 接受任意长度密钥");
        mac.update($message);
        mac.finalize().into_bytes().to_vec()
    }};
}


/// RFC 4226 动态截断。
pub(crate) fn hotp(
    secret: &[u8],
    counter: i64,
    algorithm: HashAlgorithm,
    digits: i32,
) -> Result<String, CoreError> {
    if secret.is_empty() {
        return Err(CoreError::InvalidSecret);
    }
    if counter < 0 {
        return Err(CoreError::UnsupportedParam("negative counter".into()));
    }
    if digits != 6 && digits != 8 {
        return Err(CoreError::UnsupportedParam(format!("digits {digits}")));
    }
    let message = (counter as u64).to_be_bytes();
    let mac = match algorithm {
        HashAlgorithm::Sha1 => hmac_digest!(Sha1, secret, &message),
        HashAlgorithm::Sha256 => hmac_digest!(Sha256, secret, &message),
        HashAlgorithm::Sha512 => hmac_digest!(Sha512, secret, &message),
    };
    let offset = usize::from(mac[mac.len() - 1] & 0x0f);
    let binary = (u32::from(mac[offset] & 0x7f) << 24)
        | (u32::from(mac[offset + 1]) << 16)
        | (u32::from(mac[offset + 2]) << 8)
        | u32::from(mac[offset + 3]);
    let modulus = if digits == 6 { 1_000_000 } else { 100_000_000 };
    Ok(format!("{:0width$}", binary % modulus, width = digits as usize))
}

/// RFC 6238：计数器为 `floor(unixTime / period)`。
pub(crate) fn totp(
    secret: &[u8],
    unix_time: i64,
    algorithm: HashAlgorithm,
    digits: i32,
    period: i32,
) -> Result<String, CoreError> {
    if period < 1 {
        return Err(CoreError::UnsupportedParam("period".into()));
    }
    if unix_time < 0 {
        return Err(CoreError::UnsupportedParam("negative time".into()));
    }
    hotp(secret, unix_time / i64::from(period), algorithm, digits)
}

pub(crate) fn code_for(
    account: &AccountParams,
    unix_time: i64,
) -> Result<OtpCodeResult, CoreError> {
    let code = totp(
        &account.secret,
        unix_time,
        account.algorithm,
        account.digits,
        account.period,
    )?;
    Ok(OtpCodeResult {
        id: account.id.clone(),
        code,
        remaining_seconds: remaining_seconds(unix_time, account.period),
        period: account.period,
    })
}

fn remaining_seconds(unix_time: i64, period: i32) -> i32 {
    let used = unix_time % i64::from(period);
    if used == 0 {
        period
    } else {
        period - used as i32
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const RFC_SECRET: &[u8] = b"12345678901234567890";

    #[test]
    fn rfc4226_vectors() {
        let expected = [
            "755224", "287082", "359152", "969429", "338314", "254676", "287922", "162583",
            "399871", "520489",
        ];
        for (counter, code) in expected.iter().enumerate() {
            assert_eq!(
                hotp(RFC_SECRET, counter as i64, HashAlgorithm::Sha1, 6).unwrap(),
                *code
            );
        }
    }

    #[test]
    fn eight_digits() {
        assert_eq!(
            hotp(RFC_SECRET, 0, HashAlgorithm::Sha1, 8).unwrap(),
            "84755224"
        );
    }

    #[test]
    fn rfc6238_vectors() {
        let sha256_secret = b"12345678901234567890123456789012";
        let sha512_secret =
            b"1234567890123456789012345678901234567890123456789012345678901234";
        assert_eq!(
            totp(RFC_SECRET, 59, HashAlgorithm::Sha1, 8, 30).unwrap(),
            "94287082"
        );
        assert_eq!(
            totp(sha256_secret, 59, HashAlgorithm::Sha256, 8, 30).unwrap(),
            "46119246"
        );
        assert_eq!(
            totp(sha512_secret, 59, HashAlgorithm::Sha512, 8, 30).unwrap(),
            "90693936"
        );
        assert_eq!(
            totp(sha256_secret, 1_111_111_109, HashAlgorithm::Sha256, 8, 30).unwrap(),
            "68084774"
        );
    }

    #[test]
    fn default_period_matches_explicit_thirty() {
        assert_eq!(
            totp(RFC_SECRET, 59, HashAlgorithm::Sha1, 8, 30).unwrap(),
            "94287082"
        );
    }

    #[test]
    fn six_digit_hash_variants() {
        let sha256_secret = b"12345678901234567890123456789012";
        let sha512_secret =
            b"1234567890123456789012345678901234567890123456789012345678901234";
        assert_eq!(
            hotp(sha256_secret, 37_037_036, HashAlgorithm::Sha256, 6).unwrap(),
            "084774"
        );
        assert_eq!(
            hotp(sha512_secret, 37_037_037, HashAlgorithm::Sha512, 6).unwrap(),
            "943326"
        );
        assert_eq!(
            totp(sha512_secret, 1_111_111_111, HashAlgorithm::Sha512, 8, 30).unwrap(),
            "99943326"
        );
    }

    #[test]
    fn rejects_invalid_input() {
        assert!(hotp(&[], 0, HashAlgorithm::Sha1, 6).is_err());
        assert!(hotp(RFC_SECRET, -1, HashAlgorithm::Sha1, 6).is_err());
        assert!(hotp(RFC_SECRET, 0, HashAlgorithm::Sha1, 7).is_err());
        assert!(totp(RFC_SECRET, 59, HashAlgorithm::Sha1, 6, 0).is_err());
        assert!(totp(RFC_SECRET, 59, HashAlgorithm::Sha1, 6, -30).is_err());
        assert!(totp(RFC_SECRET, -1, HashAlgorithm::Sha1, 6, 30).is_err());
    }

    #[test]
    fn remaining_seconds_wraps_to_period() {
        assert_eq!(remaining_seconds(0, 30), 30);
        assert_eq!(remaining_seconds(29, 30), 1);
        assert_eq!(remaining_seconds(30, 30), 30);
        assert_eq!(remaining_seconds(31, 30), 29);
    }
}
