import Foundation

// 存储层与 UI 之间的账户视图：算法、展示、导出都由 core 承担，这里只承载 Keychain 里的字节密钥。
public struct TOTPAccount: Sendable, Identifiable {
    public let id: String
    public let siteName: String
    public let username: String
    public let secret: Data
    public let algorithm: HashAlgorithm
    public let digits: Int
    public let period: Int

    public var name: String { username.isEmpty ? siteName : "\(siteName) \(username)" }

    public var params: AccountParams {
        AccountParams(
            id: id,
            issuer: siteName,
            accountName: username,
            secret: secret,
            algorithm: algorithm,
            digits: Int32(digits),
            period: Int32(period)
        )
    }

    public init(
        id: String,
        siteName: String,
        username: String,
        secret: Data,
        algorithm: HashAlgorithm,
        digits: Int,
        period: Int
    ) {
        self.id = id
        self.siteName = siteName
        self.username = username
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
    }
}

// 解析结果 → 表单里的「站点名 用户名」单行文本（保存时再按首个空格拆回）。
public func accountDisplayName(_ account: ParsedAccount) -> String {
    [account.issuer, account.accountName].filter { !$0.isEmpty }.joined(separator: " ")
}

// 6 位验证码按 3+3 分段显示；8 位不分段。
public func groupedCode(_ code: String, grouped: Bool) -> String {
    guard grouped, code.count == 6 else { return code }
    return "\(code.prefix(3)) \(code.suffix(3))"
}
