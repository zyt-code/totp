import AppKit
import SwiftUI
import TOTPCore

@main
@MainActor
struct TOTPApp: App {
    @State private var accounts: [TOTPAccount]
    @State private var displayName = ""
    @State private var secret = ""
    @State private var algorithm = HashAlgorithm.sha1
    @State private var digits = 6
    @State private var period = 30
    @State private var formError: String?
    @State private var windowController: AddAccountWindowController?
    @State private var settingsController: SettingsWindowController?

    init() {
        _accounts = State(initialValue: TOTPApp.loadAccountsFromDisk())
    }

    var body: some Scene {
        MenuBarExtra("TOTP", systemImage: "lock.badge.clock") {
            AccountList(
                accounts: accounts,
                onAdd: openAddAccount,
                onSettings: openSettings,
                onRename: { rename(id: $0, name: $1) },
                onDelete: delete
            )
            .task { reload() }
        }
        .menuBarExtraStyle(.window)
    }

    private func openAddAccount() {
        if windowController == nil {
            windowController = AddAccountWindowController(rootView: form)
        }
        windowController?.show()
    }

    private func openSettings() {
        if settingsController == nil {
            settingsController = SettingsWindowController(
                rootView: SettingsView(onClose: { [weak settingsController] in
                    settingsController?.close()
                })
            )
        }
        settingsController?.show()
    }

    private var form: AddAccountForm {
        AddAccountForm(
            displayName: $displayName,
            secret: $secret,
            algorithm: $algorithm,
            digits: $digits,
            period: $period,
            error: formError,
            onSave: save,
            onCancel: closeAddAccount,
            onScan: scan,
            onHeight: { windowController?.resize(to: $0) }
        )
    }

    private func closeAddAccount() {
        windowController?.close()
    }

    private func reload() {
        accounts = TOTPApp.loadAccountsFromDisk()
    }

    private static func loadAccountsFromDisk() -> [TOTPAccount] {
        guard let metadata = try? JSONMetadataRepository.applicationSupport() else { return [] }
        return (try? loadAccounts(metadata: metadata, secrets: KeychainSecretStore())) ?? []
    }

    private func rename(id: String, name: String) {
        do {
            try renameAccount(
                id: id,
                name: name,
                metadata: try JSONMetadataRepository.applicationSupport()
            )
            reload()
        } catch {
            presentError("重命名失败", "名称不能为空，请重新输入。")
        }
    }

    private func delete(id: String) {
        do {
            try deleteAccount(
                id: id,
                metadata: try JSONMetadataRepository.applicationSupport(),
                secrets: KeychainSecretStore()
            )
            reload()
        } catch {
            presentError("删除失败", "无法删除该账户，请稍后重试。")
        }
    }

    private func presentError(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }

    private func scan() {
        Task { @MainActor in
            await scanNow()
        }
    }

    private func scanNow() async {
        do {
            let fields = try await ScreenQRScanner.scan()
            displayName = fields.name
            secret = fields.secret
            algorithm = fields.algorithm
            digits = fields.digits
            period = fields.period
            formError = nil
        } catch ScreenScanError.permission {
            return
        } catch ScreenScanError.none {
            formError = "没有识别到二维码"
        } catch ScreenScanError.many {
            formError = "识别到多个二维码"
        } catch {
            formError = "二维码不是有效的 TOTP 账户"
        }
    }

    private func save() {
        do {
            let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = trimmed.split(separator: " ", maxSplits: 1).map(String.init)
            _ = try saveAccount(
                siteName: parts.first ?? "",
                username: parts.count > 1 ? parts[1] : "",
                secret: secret,
                algorithm: algorithm,
                digits: digits,
                period: period,
                metadata: try JSONMetadataRepository.applicationSupport(),
                secrets: KeychainSecretStore()
            )
            reload()
            displayName = ""
            secret = ""
            algorithm = .sha1
            digits = 6
            period = 30
            formError = nil
            closeAddAccount()
        } catch {
            formError = error is AppError ? "请检查网站名和 Secret" : "保存失败"
        }
    }
}
