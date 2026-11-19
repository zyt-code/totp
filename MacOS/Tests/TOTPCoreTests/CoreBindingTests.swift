import Foundation
import Testing
import TOTPCore

// 绑定没接错：Swift 经 FFI 算出的码必须与 Rust `cargo test` 的 RFC 6238 向量逐字一致。
// T=59、SHA-1、8 位、密钥 12345678901234567890 → 94287082。
@Test func boundCoreMatchesRFC6238Vector() throws {
    let account = AccountParams(
        id: "rfc",
        issuer: "RFC",
        accountName: "",
        secret: Data("12345678901234567890".utf8),
        algorithm: .sha1,
        digits: 8,
        period: 30
    )
    let result = try generateCode(account: account, unixTime: 59)
    #expect(result.code == "94287082")
    #expect(result.remainingSeconds == 1)
    #expect(result.period == 30)
}

// 表单里的 Base32 文本 ↔ 核心字节密钥：这条转换由核心的 otpauth 编解码承担，不能接错。
@Test func secretTextRoundTripsBase32() throws {
    let bytes = try SecretText.decode("GEZD GNBV GY3T QOJQ GEZD GNBV GY3T QOJQ")
    #expect(bytes == Data("12345678901234567890".utf8))
    #expect(SecretText.encode(bytes) == "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ")
}

@Test func secretTextRejectsNonBase32() {
    #expect((try? SecretText.decode("GEZD1")) == nil)
    #expect((try? SecretText.decode("   ")) == nil)
}

// 跨端指纹：与 Android/app/src/androidTest/.../CoreBindingTest.kt 的 crossPlatformFingerprint 用
// 完全相同的输入，输出逐字比对（任务 6.1 / 6.2 的证据）。
@Test func crossPlatformFingerprint() throws {
    let secret = Data("12345678901234567890".utf8)
    let accounts = [
        AccountParams(id: "a", issuer: "GitHub", accountName: "ada", secret: secret, algorithm: .sha1, digits: 6, period: 30),
        AccountParams(id: "b", issuer: "阿里云", accountName: "", secret: secret, algorithm: .sha512, digits: 8, period: 60),
    ]
    var parts: [String] = []
    for time: Int64 in [59, 1_111_111_109] {
        for result in generateCodesBatch(accounts: accounts, unixTime: time).sorted(by: { $0.id < $1.id }) {
            parts.append("\(result.id):\(result.code)")
        }
    }
    let json = try exportBackupJson(accounts: accounts)
    print("XPLAT codes=\(parts.joined(separator: ","))")
    print("XPLAT backup_b64=\(Data(json.utf8).base64EncodedString())")
}
