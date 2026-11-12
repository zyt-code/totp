import Foundation

private let base32Alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")

public func encodeBase32(_ data: Data) -> String {
    var output = ""
    var buffer = 0
    var bits = 0
    for byte in data {
        buffer = (buffer << 8) | Int(byte)
        bits += 8
        while bits >= 5 {
            bits -= 5
            output.append(base32Alphabet[(buffer >> bits) & 0x1F])
        }
    }
    if bits > 0 {
        output.append(base32Alphabet[(buffer << (5 - bits)) & 0x1F])
    }
    return output
}

public func otpauthURI(for account: TOTPAccount) -> String {
    let label = account.username.isEmpty
        ? escape(account.siteName)
        : "\(escape(account.siteName)):\(escape(account.username))"
    let query = [
        "secret=\(encodeBase32(account.secret.bytes))",
        "issuer=\(escape(account.siteName))",
        "algorithm=\(algorithmName(account.algorithm))",
        "digits=\(account.digits)",
        "period=\(account.period)",
    ].joined(separator: "&")
    return "otpauth://totp/\(label)?\(query)"
}

public func otpauthBackup(accounts: [TOTPAccount]) -> String {
    accounts.map(otpauthURI(for:)).joined(separator: "\n")
}

private func escape(_ text: String) -> String {
    text.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? text
}

private func algorithmName(_ algorithm: HashAlgorithm) -> String {
    switch algorithm {
    case .sha1: "SHA1"
    case .sha256: "SHA256"
    case .sha512: "SHA512"
    }
}
