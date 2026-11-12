import Foundation
import Testing
import TOTPCore

@Test func rowAtUnix59() throws {
    let account = TOTPAccount(
        id: "rfc",
        siteName: "RFC",
        username: "",
        secret: Secret(bytes: Data("12345678901234567890".utf8)),
        algorithm: .sha1,
        digits: 8,
        period: 30
    )
    #expect(try currentCode(account: account, time: 59) == "94287082")
    #expect(remainingSeconds(time: 59, period: 30) == 1)
    #expect(ringFraction(time: 59, period: 30) == 1.0 / 30)
}

@Test func remainingSecondsRestartsAtPeriodBoundary() {
    #expect(remainingSeconds(time: 60, period: 30) == 30)
    #expect(remainingSeconds(time: 0, period: 30) == 30)
    #expect(ringFraction(time: 60, period: 30) == 1)
}
