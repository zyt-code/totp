import Foundation

public struct OtpauthFields: Equatable, Sendable {
    public let name: String
    public let secret: String
    public let algorithm: HashAlgorithm
    public let digits: Int
    public let period: Int

    public init(name: String, secret: String, algorithm: HashAlgorithm, digits: Int, period: Int) {
        self.name = name
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
    }
}

public func parseOtpauth(_ text: String) throws -> OtpauthFields {
    guard let components = URLComponents(string: text),
          components.scheme == "otpauth",
          components.host == "totp" else { throw AppError.invalidSecret }
    let query = (components.queryItems ?? []).reduce(into: [String: String]()) { dict, item in
        if let value = item.value {
            dict[item.name] = value
        }
    }
    guard let secret = query["secret"], !secret.isEmpty else { throw AppError.invalidSecret }
    let label = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        .removingPercentEncoding ?? ""
    let labelParts = label.split(separator: ":", maxSplits: 1).map {
        $0.trimmingCharacters(in: .whitespaces)
    }
    let issuer = query["issuer"]?
        .replacingOccurrences(of: "+", with: " ")
        .trimmingCharacters(in: .whitespaces)
        .nonEmpty
    let account = (labelParts.count == 2 ? labelParts[1] : labelParts.first)?.nonEmpty
    let name = [issuer ?? (labelParts.count == 2 ? labelParts[0] : nil), account]
        .compactMap(\.self)
        .joined(separator: " ")
    return OtpauthFields(
        name: name,
        secret: secret,
        algorithm: try algorithm(query["algorithm"]),
        digits: try digits(query["digits"]),
        period: try period(query["period"])
    )
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}

private func algorithm(_ value: String?) throws -> HashAlgorithm {
    switch value?.uppercased() {
    case nil, "SHA1": .sha1
    case "SHA256": .sha256
    case "SHA512": .sha512
    default: throw AppError.invalidSecret
    }
}

private func digits(_ value: String?) throws -> Int {
    switch value {
    case nil, "6": 6
    case "8": 8
    default: throw AppError.invalidSecret
    }
}

private func period(_ value: String?) throws -> Int {
    guard let value else { return 30 }
    guard let period = Int(value), period > 0 else { throw AppError.invalidSecret }
    return period
}
