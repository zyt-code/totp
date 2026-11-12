import CryptoKit
import Foundation

public func totp(
    secret: Secret,
    time: Int,
    algorithm: HashAlgorithm,
    digits: Int,
    period: Int = 30
) throws -> String {
    guard period > 0 else { throw AppError.invalidPeriod }
    return try hotp(
        secret: secret,
        counter: time / period,
        algorithm: algorithm,
        digits: digits
    )
}

public func hotp(
    secret: Secret,
    counter: Int,
    algorithm: HashAlgorithm,
    digits: Int
) throws -> String {
    guard !secret.bytes.isEmpty else { throw AppError.emptySecret }
    guard counter >= 0 else { throw AppError.negativeCounter }
    guard digits == 6 || digits == 8 else { throw AppError.invalidDigits }

    var bigEndian = UInt64(counter).bigEndian
    let message = Data(bytes: &bigEndian, count: MemoryLayout<UInt64>.size)
    let mac = hmac(algorithm, key: secret.bytes, message: message)
    let offset = Int(mac[mac.count - 1] & 0x0f)
    let binary = Int(mac[offset] & 0x7f) << 24
        | Int(mac[offset + 1]) << 16
        | Int(mac[offset + 2]) << 8
        | Int(mac[offset + 3])
    let code = binary % (digits == 6 ? 1_000_000 : 100_000_000)
    return String(format: "%0*d", digits, code)
}

private func hmac(_ algorithm: HashAlgorithm, key: Data, message: Data) -> Data {
    switch algorithm {
    case .sha1:
        Data(CryptoKit.HMAC<Insecure.SHA1>.authenticationCode(for: message, using: SymmetricKey(data: key)))
    case .sha256:
        Data(CryptoKit.HMAC<SHA256>.authenticationCode(for: message, using: SymmetricKey(data: key)))
    case .sha512:
        Data(CryptoKit.HMAC<SHA512>.authenticationCode(for: message, using: SymmetricKey(data: key)))
    }
}
