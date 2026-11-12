import Foundation
import Testing
import TOTPCore

private let seed20 = Data("12345678901234567890".utf8)
private let seed32 = Data(String(repeating: "12345678901234567890", count: 2).prefix(32).utf8)
private let seed64 = Data(String(repeating: "12345678901234567890", count: 4).prefix(64).utf8)

@Test func hotpRFC4226CounterZero() throws {
    let secret = Secret(bytes: seed20)
    #expect(try hotp(secret: secret, counter: 0, algorithm: .sha1, digits: 6) == "755224")
    #expect(try hotp(secret: secret, counter: 0, algorithm: .sha1, digits: 8) == "84755224")
}

@Test func hotpSHA256AndSHA512SixDigits() throws {
    // 6 digits are the same RFC 6238 truncation as the published 8-digit values.
    let sha256 = Secret(bytes: seed32)
    let sha512 = Secret(bytes: seed64)
    #expect(try hotp(secret: sha256, counter: 37_037_036, algorithm: .sha256, digits: 6) == "084774")
    #expect(try hotp(secret: sha512, counter: 37_037_037, algorithm: .sha512, digits: 6) == "943326")
}

@Test func hotpRejectsInvalidInput() {
    #expect(throws: AppError.emptySecret) {
        try hotp(secret: Secret(bytes: Data()), counter: 0, algorithm: .sha1, digits: 6)
    }
    #expect(throws: AppError.negativeCounter) {
        try hotp(secret: Secret(bytes: seed20), counter: -1, algorithm: .sha1, digits: 6)
    }
    #expect(throws: AppError.invalidDigits) {
        try hotp(secret: Secret(bytes: seed20), counter: 0, algorithm: .sha1, digits: 7)
    }
}
