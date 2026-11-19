use crate::model::CoreError;

const ALPHABET: &[u8; 32] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

/// 忽略空格与连字符，其余按 Base32 解码；空串、非法字符、非法 padding 一律拒绝。
pub(crate) fn decode(text: &str) -> Result<Vec<u8>, CoreError> {
    let cleaned: Vec<u8> = text
        .to_ascii_uppercase()
        .bytes()
        .filter(|b| !b.is_ascii_whitespace() && *b != b'-')
        .collect();
    if cleaned.is_empty() {
        return Err(CoreError::InvalidSecret);
    }
    let mut output = Vec::with_capacity(cleaned.len() * 5 / 8);
    let mut buffer: u32 = 0;
    let mut bits = 0u32;
    let mut padding = 0usize;
    for byte in &cleaned {
        if *byte == b'=' {
            padding += 1;
            continue;
        }
        if padding != 0 {
            return Err(CoreError::InvalidSecret);
        }
        let value = ALPHABET
            .iter()
            .position(|c| c == byte)
            .ok_or(CoreError::InvalidSecret)? as u32;
        buffer = (buffer << 5) | value;
        bits += 5;
        if bits >= 8 {
            bits -= 8;
            output.push(((buffer >> bits) & 0xff) as u8);
        }
    }
    if (padding != 0 && cleaned.len() % 8 != 0) || output.is_empty() {
        return Err(CoreError::InvalidSecret);
    }
    Ok(output)
}

pub(crate) fn encode(data: &[u8]) -> String {
    let mut output = String::with_capacity(data.len().div_ceil(5) * 8);
    let mut buffer: u32 = 0;
    let mut bits = 0u32;
    for byte in data {
        buffer = (buffer << 8) | u32::from(*byte);
        bits += 8;
        while bits >= 5 {
            bits -= 5;
            output.push(ALPHABET[((buffer >> bits) & 0x1f) as usize] as char);
        }
    }
    if bits > 0 {
        output.push(ALPHABET[((buffer << (5 - bits)) & 0x1f) as usize] as char);
    }
    output
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ignores_spaces() {
        let decoded = decode("GEZD GNBV GY3T QOJQ GEZD GNBV GY3T QOJQ").unwrap();
        assert_eq!(decoded, b"12345678901234567890");
    }

    #[test]
    fn rejects_invalid_character() {
        assert!(decode("GEZD1").is_err());
    }

    #[test]
    fn rejects_empty() {
        assert!(decode("").is_err());
        assert!(decode("   ").is_err());
    }

    #[test]
    fn rejects_invalid_padding() {
        assert!(decode("AA=").is_err());
        assert!(decode("A===").is_err());
        assert!(decode("GEZD==").is_err());
    }

    #[test]
    fn round_trips() {
        let text = "GEZD GNBV GY3T QOJQ GEZD GNBV GY3T QOJQ";
        assert_eq!(encode(&decode(text).unwrap()), "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ");
    }
}
