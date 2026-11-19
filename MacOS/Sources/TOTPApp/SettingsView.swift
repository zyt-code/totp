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

    var body: some View {
        Form {
            Section("常规") {
                Toggle("登录时自动启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLoginItem(enabled) }
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
        .onAppear { launchAtLogin = SMAppService.mainApp.status == .enabled }
    }

    private func setLoginItem(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginError = nil
        } catch {
            loginError = "无法\(enabled ? "开启" : "关闭")登录时自动启动：\(error.localizedDescription)"
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func exportBackup() {
        let accounts = currentAccounts()
        guard !accounts.isEmpty else {
            presentAlert("没有可导出的账户", "先在菜单栏里添加账户。")
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
            presentAlert("导出失败", error.localizedDescription)
        }
    }

    // 导出时重新读取，避免用设置窗口打开那一刻的旧快照。
    private func currentAccounts() -> [TOTPAccount] {
        guard let metadata = try? JSONMetadataRepository.applicationSupport() else { return [] }
        return (try? loadAccounts(metadata: metadata, secrets: KeychainSecretStore())) ?? []
    }

    private func presentAlert(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}
