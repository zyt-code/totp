import Foundation
import Testing
import TOTPCore

@Test func secretDescriptionOmitsMaterial() {
    let raw = Data("12345678901234567890".utf8)
    let secret = Secret(bytes: raw)
    let hex = raw.map { String(format: "%02x", $0) }.joined()
    let rendered = "\(secret) \(String(reflecting: secret))"
    #expect(!rendered.contains("12345678901234567890"))
    #expect(!rendered.localizedCaseInsensitiveContains(hex))
    #expect(!rendered.localizedCaseInsensitiveContains("GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"))
}
