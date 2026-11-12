import Foundation

public enum HashAlgorithm: String, Codable, Sendable {
    case sha1
    case sha256
    case sha512
}

public struct Secret: Sendable {
    let bytes: Data

    public init(bytes: Data) {
        self.bytes = bytes
    }
}

extension Secret: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String { "Secret(<redacted>)" }
    public var debugDescription: String { description }
}

public enum AppError: Error, Equatable, Sendable {
    case emptySecret
    case negativeCounter
    case invalidDigits
    case invalidPeriod
    case invalidSecret
    case blankSiteName
}

public func decodeBase32(_ text: String) throws -> Data {
    let cleaned = text.uppercased().filter { !$0.isWhitespace && $0 != "-" }
    guard !cleaned.isEmpty else { throw AppError.invalidSecret }
    let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
    var buffer = 0
    var bits = 0
    var output = Data()
    var padding = 0
    for character in cleaned {
        if character == "=" {
            padding += 1
            continue
        }
        guard padding == 0, let value = alphabet.firstIndex(of: character) else { throw AppError.invalidSecret }
        buffer = (buffer << 5) | value
        bits += 5
        if bits >= 8 {
            bits -= 8
            output.append(UInt8((buffer >> bits) & 0xff))
        }
    }
    guard padding == 0 || cleaned.count.isMultiple(of: 8), output.isEmpty == false else { throw AppError.invalidSecret }
    return output
}
