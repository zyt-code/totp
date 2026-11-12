import Foundation
import Testing
import TOTPCore

private let canonicalSecret = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"

@Test func base32RoundTrips() throws {
    let decoded = try decodeBase32("GEZD GNBV GY3T QOJQ GEZD GNBV GY3T QOJQ")
    #expect(encodeBase32(decoded) == canonicalSecret)
    #expect(try decodeBase32(encodeBase32(decoded)) == decoded)
}

@Test func otpauthURIRoundTrips() throws {
    let account = TOTPAccount(
        id: "a",
        siteName: "GitHub",
        username: "ada",
        secret: Secret(bytes: try decodeBase32(canonicalSecret)),
        algorithm: .sha256,
        digits: 8,
        period: 45
    )
    let parsed = try parseOtpauth(otpauthURI(for: account))
    #expect(parsed.secret == canonicalSecret)
    #expect(parsed.algorithm == .sha256)
    #expect(parsed.digits == 8)
    #expect(parsed.period == 45)
    #expect(parsed.name == "GitHub ada")
}

@Test func backupSeparatesAccountsByLine() throws {
    let secret = Secret(bytes: try decodeBase32(canonicalSecret))
    let accounts = [
        TOTPAccount(id: "a", siteName: "GitHub", username: "ada", secret: secret, algorithm: .sha1, digits: 6, period: 30),
        TOTPAccount(id: "b", siteName: "Work", username: "", secret: secret, algorithm: .sha512, digits: 8, period: 60),
    ]
    let lines = otpauthBackup(accounts: accounts).split(separator: "\n")
    #expect(lines.count == 2)
    #expect(lines.allSatisfy { $0.hasPrefix("otpauth://totp/") })
}
