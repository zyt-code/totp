import Foundation
import Testing
import TOTPCore

@Test func base32IgnoresSpaces() throws {
    let decoded = try decodeBase32("GEZD GNBV GY3T QOJQ GEZD GNBV GY3T QOJQ")
    #expect(String(decoding: decoded, as: UTF8.self) == "12345678901234567890")
}

@Test func base32RejectsInvalidInput() {
    #expect(throws: AppError.invalidSecret) { try decodeBase32("") }
    #expect(throws: AppError.invalidSecret) { try decodeBase32("   ") }
    #expect(throws: AppError.invalidSecret) { try decodeBase32("GEZD1") }
    #expect(throws: AppError.invalidSecret) { try decodeBase32("GEZD==") }
}
