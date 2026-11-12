import Foundation
import Testing
import TOTPCore

private let first = AccountMetadata(id: "a", siteName: "GitHub", username: "ada", algorithm: .sha1, digits: 6, period: 30)
private let second = AccountMetadata(id: "b", siteName: "Work", username: "", algorithm: .sha256, digits: 8, period: 30)

private func code(_ secret: Secret) throws -> String {
    try totp(secret: secret, time: 59, algorithm: .sha1, digits: 8, period: 30)
}

@Test func memorySecretStoreRoundTrip() throws {
    let store = MemorySecretStore()
    let original = Secret(bytes: Data("12345678901234567890".utf8))
    store.save(id: "a", secret: original)
    #expect(try code(store.load(id: "a")!) == "94287082")

    let replacement = Secret(bytes: Data("12345678901234567891".utf8))
    store.save(id: "a", secret: replacement)
    #expect(try code(store.load(id: "a")!) != "94287082")

    #expect(store.load(id: "missing") == nil)
    store.delete(id: "missing")
    #expect(try code(store.load(id: "a")!) != "94287082")

    store.delete(id: "a")
    #expect(store.load(id: "a") == nil)
}

@Test func memoryMetadataKeepsOrderAndOmitsSecrets() throws {
    let repository = MemoryMetadataRepository()
    repository.save(first)
    repository.save(second)
    #expect(repository.list().map(\.id) == ["a", "b"])

    var renamed = first
    renamed.siteName = "GitLab"
    repository.save(renamed)
    #expect(repository.list().map(\.siteName) == ["GitLab", "Work"])

    let rendered = repository.list().map(String.init(describing:)).joined(separator: " ")
    #expect(!rendered.contains("secret"))
    #expect(!rendered.localizedCaseInsensitiveContains("313233"))

    repository.delete(id: "a")
    #expect(repository.list().map(\.id) == ["b"])
}

private struct FailingMetadataRepository: AccountMetadataRepository {
    func save(_ metadata: AccountMetadata) throws { throw AppError.blankSiteName }
    func list() throws -> [AccountMetadata] { [] }
    func delete(id: String) throws {}
}

@Test func saveAccountWritesBothStores() throws {
    let metadata = MemoryMetadataRepository()
    let secrets = MemorySecretStore()
    let saved = try saveAccount(
        siteName: " GitHub ",
        username: " ada ",
        secret: "GEZD GNBV GY3T QOJQ GEZD GNBV GY3T QOJQ",
        algorithm: .sha256,
        digits: 8,
        period: 30,
        metadata: metadata,
        secrets: secrets
    )
    #expect(metadata.list() == [saved])
    #expect(saved.siteName == "GitHub")
    #expect(saved.username == "ada")
    #expect(try code(secrets.load(id: saved.id)! ) == "94287082")
    #expect(String(describing: saved).contains("94287082") == false)
}

@Test func saveAccountRejectsBlankSite() {
    let metadata = MemoryMetadataRepository()
    let secrets = MemorySecretStore()
    #expect(throws: AppError.blankSiteName) {
        try saveAccount(siteName: "  ", username: "", secret: "GEZDGNBV", algorithm: .sha1, digits: 6, period: 30, metadata: metadata, secrets: secrets)
    }
    #expect(metadata.list().isEmpty)
}

@Test func saveAccountRollsBackSecret() throws {
    let secrets = MemorySecretStore()
    #expect(throws: AppError.blankSiteName) {
        try saveAccount(siteName: "GitHub", username: "", secret: "GEZDGNBV", algorithm: .sha1, digits: 6, period: 30, metadata: FailingMetadataRepository(), secrets: secrets)
    }
    #expect(secrets.savedIDs.isEmpty)
}

@Test func loadAccountsSkipsMissingSecrets() throws {
    let metadata = MemoryMetadataRepository()
    let secrets = MemorySecretStore()
    metadata.save(first)
    metadata.save(second)
    secrets.save(id: "a", secret: Secret(bytes: Data("12345678901234567890".utf8)))

    let accounts = try loadAccounts(metadata: metadata, secrets: secrets)
    #expect(accounts.map(\.name) == ["GitHub ada"])
    #expect(accounts.map(\.id) == ["a"])
    #expect(try code(accounts[0].secret) == "94287082")
}
