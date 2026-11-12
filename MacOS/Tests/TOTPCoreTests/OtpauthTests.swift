import Testing
import TOTPCore

@Test func otpauthFullURI() throws {
    let parsed = try parseOtpauth("otpauth://totp/GitHub:ada?secret=GEZDGNBV&issuer=GitHub&algorithm=SHA256&digits=8&period=45")
    #expect(parsed == OtpauthFields(name: "GitHub ada", secret: "GEZDGNBV", algorithm: .sha256, digits: 8, period: 45))
}

@Test func otpauthDefaults() throws {
    let parsed = try parseOtpauth("otpauth://totp/GitHub?secret=GEZDGNBV")
    #expect(parsed.algorithm == .sha1)
    #expect(parsed.digits == 6)
    #expect(parsed.period == 30)
    #expect(parsed.name == "GitHub")
}

@Test func otpauthDecodesPlusAsSpaceInIssuer() throws {
    // Spot Auth 等导出器把 issuer 里的空格编成 +，名称不应保留加号。
    let parsed = try parseOtpauth("otpauth://totp/Spot%20Auth%20Lab:test%40spot-auth.app?secret=GEZDGNBV&issuer=Spot+Auth+Lab")
    #expect(parsed.name == "Spot Auth Lab test@spot-auth.app")
}

@Test func otpauthRejectsInvalidURI() {
    #expect(throws: AppError.invalidSecret) {
        try parseOtpauth("otpauth://totp/GitHub")
    }
    #expect(throws: AppError.invalidSecret) {
        try parseOtpauth("otpauth://totp/GitHub?secret=GEZDGNBV&algorithm=SHA384")
    }
}
