import AppKit
import ServiceManagement
import SwiftUI
import TOTPCore
import UniformTypeIdentifiers

struct SettingsView: View {
    var onClose: () -> Void = {}

    @AppStorage(SettingKey.clipboardAutoClear) private var clipboardAutoClear = SettingKey.defaultClipboardAutoClear
    @AppStorage(SettingKey.clipboardClearDelay) private var clipboardClearDelay = SettingKey.defaultClipboardClearDelay
    @AppStorage(SettingKey.groupCodes) private var groupCodes = SettingKey.defaultGroupCodes

    @State private var launchAtLogin = false
    @State private var loginError: String?
    @State private var importing = false

    var body: some View {
        Form {
            Section("常规") {
                Toggle("登录时自动启动", isOn: Binding(
                    get: { launchAtLogin },
                    set: { setLoginItem($0) }
                ))
                if let loginError {
                    Text(loginError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Section("安全") {
                Toggle("复制后自动清空剪贴板", isOn: $clipboardAutoClear)
                Picker("延迟", selection: $clipboardClearDelay) {
                    Text("15 秒").tag(15)
                    Text("30 秒").tag(30)
                    Text("60 秒").tag(60)
                }
                .disabled(!clipboardAutoClear)
            }
            Section("显示") {
                Toggle("验证码分段显示", isOn: $groupCodes)
            }
            Section("数据与关于") {
                Button("导出备份（JSON）", action: exportBackup)
                Button(importing ? "正在导入..." : "导入备份（JSON）", action: importBackup)
                    .disabled(importing)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(AppInfo.name) v\(AppInfo.version)")
                    Text(AppInfo.storageStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .onExitCommand(perform: onClose)
        .onAppear {
            let status = SMAppService.mainApp.status
            launchAtLogin = (status == .enabled || status == .requiresApproval)
            if status == .requiresApproval {
                loginError = "已请求开启开机启动，请在 macOS 系统设置的「登录项」中批准。"
            }
        }
    }

    private func setLoginItem(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            let status = SMAppService.mainApp.status
            if status == .requiresApproval {
                launchAtLogin = true
                loginError = "已请求开启开机启动，请在 macOS 系统设置的「登录项」中批准。"
            } else {
                launchAtLogin = (status == .enabled)
                loginError = nil
            }
        } catch {
            loginError = "无法\(enabled ? "开启" : "关闭")登录时自动启动：\(error.localizedDescription)"
            let status = SMAppService.mainApp.status
            launchAtLogin = (status == .enabled || status == .requiresApproval)
        }
    }

    private func importBackup() {
        guard !importing else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "选择要导入的 JSON 备份文件"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        importing = true
        Task.detached {
            let parseResult: Result<BackupImport, Error>
            do {
                let data = try Data(contentsOf: url)
                guard let text = String(data: data, encoding: .utf8) else {
                    await MainActor.run {
                        importing = false
                        Self.presentAlert("导入失败", "文件不是有效的 UTF-8 编码。")
                    }
                    return
                }
                let imported = try importBackupJson(text: text)
                parseResult = .success(imported)
            } catch {
                parseResult = .failure(error)
            }

            await MainActor.run {
                defer { importing = false }
                switch parseResult {
                case .success(let imported):
                    do {
                        let metadataRepo = try JSONMetadataRepository.applicationSupport()
                        let secretStore = KeychainSecretStore()

                        var savedCount = 0
                        var failedCount = 0
                        for account in imported.accounts {
                            do {
                                let site = account.issuer.isEmpty ? account.accountName : account.issuer
                                let user = account.issuer.isEmpty ? "" : account.accountName
                                _ = try saveAccount(
                                    siteName: site,
                                    username: user,
                                    secret: SecretText.encode(account.secret),
                                    algorithm: account.algorithm,
                                    digits: Int(account.digits),
                                    period: Int(account.period),
                                    metadata: metadataRepo,
                                    secrets: secretStore
                                )
                                savedCount += 1
                            } catch {
                                failedCount += 1
                            }
                        }
                        let formatSkipped = Int(imported.skipped)
                        let alertMessage: String
                        if failedCount > 0 {
                            alertMessage = "成功导入 \(savedCount) 个账户，格式无效跳过 \(formatSkipped) 个，保存失败 \(failedCount) 个。"
                        } else {
                            alertMessage = "成功导入 \(savedCount) 个账户，跳过 \(formatSkipped) 个。"
                        }
                        Self.presentAlert("导入完成", alertMessage)
                    } catch {
                        Self.presentAlert("导入失败", error.localizedDescription)
                    }
                case .failure(CoreError.BackupFormat(let msg)):
                    Self.presentAlert("导入失败", msg)
                case .failure(let error):
                    Self.presentAlert("导入失败", error.localizedDescription)
                }
            }
        }
    }

    private func exportBackup() {
        let accounts = currentAccounts()
        guard !accounts.isEmpty else {
            Self.presentAlert("没有可导出的账户", "先在菜单栏里添加账户。")
            return
        }

        let confirm = NSAlert()
        confirm.messageText = "导出备份"
        confirm.informativeText = "将导出 \(accounts.count) 个账户的 JSON 备份。备份包含密钥，请妥善保管。"
        confirm.addButton(withTitle: "继续")
        confirm.addButton(withTitle: "取消")
        guard confirm.runModal() == .alertFirstButtonReturn else { return }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "totp-backup.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try exportBackupJson(accounts: accounts.map(\.params)).write(to: url, atomically: true, encoding: .utf8)
        } catch {
            Self.presentAlert("导出失败", error.localizedDescription)
        }
    }

    // 导出时重新读取，避免用设置窗口打开那一刻的旧快照。
    private func currentAccounts() -> [TOTPAccount] {
        guard let metadata = try? JSONMetadataRepository.applicationSupport() else { return [] }
        return (try? loadAccounts(metadata: metadata, secrets: KeychainSecretStore())) ?? []
    }

    @MainActor
    private static func presentAlert(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}
