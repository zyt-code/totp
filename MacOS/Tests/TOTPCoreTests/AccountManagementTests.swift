import Foundation
import Testing
import TOTPCore

@Test func displayPartsDecodesPlus() {
    let parts = displayParts(siteName: "Spot+Auth+Lab", username: "")
    #expect(parts.title == "Spot Auth Lab")
    #expect(parts.subtitle == nil)
}

@Test func displayPartsDecodesPercentEscapes() {
    #expect(displayParts(siteName: "Spot%20Auth", username: "").title == "Spot Auth")
}

@Test func displayPartsSplitsOnFirstColon() {
    let parts = displayParts(siteName: "OpenAI:ada@example.com", username: "")
    #expect(parts.title == "OpenAI")
    #expect(parts.subtitle == "ada@example.com")
}

@Test func displayPartsKeepsUsernameAsSubtitle() {
    let parts = displayParts(siteName: "GitHub", username: "ada")
    #expect(parts.title == "GitHub")
    #expect(parts.subtitle == "ada")
}

@Test func formattedCodeGroupsSixDigits() {
    #expect(formattedCode("404162") == "404 162")
    #expect(formattedCode("12345678") == "12345678")
}

@Test func renameAccountPersistsSplitName() throws {
    let repository = MemoryMetadataRepository()
    repository.save(AccountMetadata(id: "a", siteName: "GitHub", username: "ada", algorithm: .sha1, digits: 6, period: 30))
    try renameAccount(id: "a", name: "GitLab ada", metadata: repository)
    let record = try #require(repository.list().first)
    #expect(record.siteName == "GitLab")
    #expect(record.username == "ada")
}

@Test func renameAccountRejectsBlankName() throws {
    let repository = MemoryMetadataRepository()
    repository.save(AccountMetadata(id: "a", siteName: "GitHub", username: "ada", algorithm: .sha1, digits: 6, period: 30))
    #expect(throws: AppError.blankSiteName) {
        try renameAccount(id: "a", name: "   ", metadata: repository)
    }
    #expect(try repository.list().first?.siteName == "GitHub")
}

@Test func deleteAccountRemovesSecretAndMetadata() throws {
    let metadata = MemoryMetadataRepository()
    let secrets = MemorySecretStore()
    let saved = try saveAccount(
        siteName: "GitHub",
        username: "ada",
        secret: "GEZD GNBV GY3T QOJQ GEZD GNBV GY3T QOJQ",
        algorithm: .sha1,
        digits: 6,
        period: 30,
        metadata: metadata,
        secrets: secrets
    )
    try deleteAccount(id: saved.id, metadata: metadata, secrets: secrets)
    #expect(metadata.list().isEmpty)
    #expect(secrets.savedIDs.isEmpty)
}
