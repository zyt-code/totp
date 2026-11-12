import Foundation
import Testing
import TOTPCore

private let seed20 = Data("12345678901234567890".utf8)
private let seed32 = Data(String(repeating: "12345678901234567890", count: 2).prefix(32).utf8)
private let seed64 = Data(String(repeating: "12345678901234567890", count: 4).prefix(64).utf8)

@Test func totpRFC6238() throws {
    #expect(try totp(secret: Secret(bytes: seed20), time: 59, algorithm: .sha1, digits: 8, period: 30) == "94287082")
    #expect(try totp(secret: Secret(bytes: seed32), time: 1_111_111_109, algorithm: .sha256, digits: 8, period: 30) == "68084774")
    #expect(try totp(secret: Secret(bytes: seed64), time: 1_111_111_111, algorithm: .sha512, digits: 8, period: 30) == "99943326")
}

@Test func totpDefaultsToThirtySeconds() throws {
    let secret = Secret(bytes: seed20)
    let explicit = try totp(secret: secret, time: 59, algorithm: .sha1, digits: 8, period: 30)
    let implicit = try totp(secret: secret, time: 59, algorithm: .sha1, digits: 8)
    #expect(implicit == explicit)
}

@Test func totpRejectsNonPositivePeriod() {
    #expect(throws: AppError.invalidPeriod) {
        try totp(secret: Secret(bytes: seed20), time: 59, algorithm: .sha1, digits: 8, period: 0)
    }
    #expect(throws: AppError.invalidPeriod) {
        try totp(secret: Secret(bytes: seed20), time: 59, algorithm: .sha1, digits: 8, period: -30)
    }
}
