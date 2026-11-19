import Foundation

// 存储层只认字节：密钥不进文本层（core 侧同样只以字节跨边界）。
public enum AppError: Error, Equatable, Sendable {
    case blankSiteName
    case invalidSecret
}

public protocol SecretStore: Sendable {
    func save(id: String, secret: Data) throws
    func load(id: String) throws -> Data?
    func delete(id: String) throws
}

public final class MemorySecretStore: SecretStore, @unchecked Sendable {
    private var secrets: [String: Data] = [:]
    public var savedIDs: [String] { Array(secrets.keys) }

    public init() {}

    public func save(id: String, secret: Data) {
        secrets[id] = secret
    }

    public func load(id: String) -> Data? {
        secrets[id]
    }

    public func delete(id: String) {
        secrets[id] = nil
    }
}

// 绑定里的 HashAlgorithm 不带 Codable：元数据落盘沿用旧的字符串取值（sha1/sha256/sha512）。
extension HashAlgorithm: Codable {
    public init(from decoder: Decoder) throws {
        switch try decoder.singleValueContainer().decode(String.self) {
        case "sha1": self = .sha1
        case "sha256": self = .sha256
        case "sha512": self = .sha512
        default: throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "未知算法"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let name = switch self {
        case .sha1: "sha1"
        case .sha256: "sha256"
        case .sha512: "sha512"
        }
        try container.encode(name)
    }
}

public struct AccountMetadata: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public var siteName: String
    public var username: String
    public var algorithm: HashAlgorithm
    public var digits: Int
    public var period: Int

    public init(id: String, siteName: String, username: String, algorithm: HashAlgorithm, digits: Int, period: Int) {
        self.id = id
        self.siteName = siteName
        self.username = username
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
    }
}

extension AccountMetadata: CustomStringConvertible {
    public var description: String { "\(siteName) \(username)" }
}

public protocol AccountMetadataRepository: Sendable {
    func save(_ metadata: AccountMetadata) throws
    func list() throws -> [AccountMetadata]
    func delete(id: String) throws
}

public final class MemoryMetadataRepository: AccountMetadataRepository, @unchecked Sendable {
    private var records: [AccountMetadata] = []

    public init() {}

    public func save(_ metadata: AccountMetadata) {
        if let index = records.firstIndex(where: { $0.id == metadata.id }) {
            records[index] = metadata
        } else {
            records.append(metadata)
        }
    }

    public func list() -> [AccountMetadata] { records }

    public func delete(id: String) {
        records.removeAll { $0.id == id }
    }
}

public struct KeychainSecretStore: SecretStore {
    public init() {}

    public func save(id: String, secret: Data) throws {
        try delete(id: id)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Self.service,
            kSecAttrAccount: id,
            kSecValueData: secret,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    public func load(id: String) throws -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Self.service,
            kSecAttrAccount: id,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else { throw KeychainError(status: status) }
        return data
    }

    public func delete(id: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Self.service,
            kSecAttrAccount: id,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError(status: status) }
    }

    private static let service = "local.totp.secret"
}

public struct KeychainError: Error, Equatable {
    public let status: OSStatus
}

public struct JSONMetadataRepository: AccountMetadataRepository {
    private let url: URL

    public init(url: URL) {
        self.url = url
    }

    public static func applicationSupport() throws -> JSONMetadataRepository {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appending(path: "totp", directoryHint: .isDirectory)
        return JSONMetadataRepository(url: directory.appending(path: "accounts.json"))
    }

    public func save(_ metadata: AccountMetadata) throws {
        var records = try list()
        if let index = records.firstIndex(where: { $0.id == metadata.id }) {
            records[index] = metadata
        } else {
            records.append(metadata)
        }
        try write(records)
    }

    public func list() throws -> [AccountMetadata] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return try JSONDecoder().decode([AccountMetadata].self, from: Data(contentsOf: url))
    }

    public func delete(id: String) throws {
        try write(list().filter { $0.id != id })
    }

    private func write(_ records: [AccountMetadata]) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(records).write(to: url, options: .atomic)
    }
}

public func saveAccount(
    siteName: String,
    username: String,
    secret: String,
    algorithm: HashAlgorithm,
    digits: Int,
    period: Int,
    metadata repository: AccountMetadataRepository,
    secrets: SecretStore
) throws -> AccountMetadata {
    let site = siteName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !site.isEmpty else { throw AppError.blankSiteName }
    guard let decoded = try? SecretText.decode(secret) else { throw AppError.invalidSecret }
    let id = UUID().uuidString
    try secrets.save(id: id, secret: decoded)
    let metadata = AccountMetadata(
        id: id,
        siteName: site,
        username: username.trimmingCharacters(in: .whitespacesAndNewlines),
        algorithm: algorithm,
        digits: digits,
        period: period
    )
    do {
        try repository.save(metadata)
    } catch {
        try? secrets.delete(id: id)
        throw error
    }
    return metadata
}

public func loadAccounts(metadata: AccountMetadataRepository, secrets: SecretStore) throws -> [TOTPAccount] {
    try metadata.list().compactMap { record in
        guard let secret = try secrets.load(id: record.id) else { return nil }
        return TOTPAccount(
            id: record.id,
            siteName: record.siteName,
            username: record.username,
            secret: secret,
            algorithm: record.algorithm,
            digits: record.digits,
            period: record.period
        )
    }
}

public func renameAccount(
    id: String,
    name: String,
    metadata repository: AccountMetadataRepository
) throws {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { throw AppError.blankSiteName }
    guard var record = try repository.list().first(where: { $0.id == id }) else { return }
    let parts = trimmed.split(separator: " ", maxSplits: 1).map(String.init)
    record.siteName = parts.first ?? trimmed
    record.username = parts.count > 1 ? parts[1] : ""
    try repository.save(record)
}

// 先删密钥再删元数据：即使元数据删除失败，加载时也会因缺密钥跳过该记录，不留孤立钥匙串条目。
public func deleteAccount(
    id: String,
    metadata repository: AccountMetadataRepository,
    secrets: SecretStore
) throws {
    try secrets.delete(id: id)
    try repository.delete(id: id)
}
