import Foundation

public struct TOTPAccount: Sendable, Identifiable {
    public let id: String
    public let siteName: String
    public let username: String
    public let secret: Secret
    public let algorithm: HashAlgorithm
    public let digits: Int
    public let period: Int

    public var name: String { username.isEmpty ? siteName : "\(siteName) \(username)" }

    public init(
        id: String,
        siteName: String,
        username: String,
        secret: Secret,
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

public func remainingSeconds(time: Int, period: Int) -> Int {
    let used = time % period
    return used == 0 ? period : period - used
}

public func ringFraction(time: Int, period: Int) -> Double {
    Double(remainingSeconds(time: time, period: period)) / Double(period)
}

public func currentCode(account: TOTPAccount, time: Int) throws -> String {
    try totp(
        secret: account.secret,
        time: time,
        algorithm: account.algorithm,
        digits: account.digits,
        period: account.period
    )
}

// 展示用拆分：先还原编码，再在副标题缺失时按首个冒号拆开 Issuer:Account。
public func displayParts(siteName: String, username: String) -> (title: String, subtitle: String?) {
    let site = decodedDisplayText(siteName)
    let user = decodedDisplayText(username)
    if !user.isEmpty { return (site, user) }
    if let colon = site.firstIndex(of: ":") {
        let title = String(site[..<colon]).trimmingCharacters(in: .whitespaces)
        let subtitle = String(site[site.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
        if !title.isEmpty, !subtitle.isEmpty { return (title, subtitle) }
    }
    return (site, nil)
}

public func formattedCode(_ code: String, grouped: Bool = true) -> String {
    guard grouped, code.count == 6 else { return code }
    let split = code.index(code.startIndex, offsetBy: 3)
    return "\(code[..<split]) \(code[split...])"
}

private func decodedDisplayText(_ text: String) -> String {
    (text.replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? text)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}
