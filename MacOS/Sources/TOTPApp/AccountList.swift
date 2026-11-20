import AppKit
import SwiftUI
import TOTPCore

struct AccountList: View {
    var accounts: [TOTPAccount]
    var onAdd: () -> Void
    var onSettings: () -> Void = {}
    var onRename: (String, String) -> Void = { _, _ in }
    var onDelete: (String) -> Void = { _ in }
    var clipboard: Clipboard = SystemClipboard()

    @AppStorage(SettingKey.groupCodes) private var groupCodes = SettingKey.defaultGroupCodes
    @AppStorage(SettingKey.clipboardAutoClear) private var clipboardAutoClear = SettingKey.defaultClipboardAutoClear
    @AppStorage(SettingKey.clipboardClearDelay) private var clipboardClearDelay = SettingKey.defaultClipboardClearDelay

    @State private var hoveredID: String?
    @State private var copiedID: String?
    @State private var tick = Date()
    @State private var renaming: TOTPAccount?
    @State private var renameText = ""
    @State private var deleting: TOTPAccount?
    @State private var copyResetTask: Task<Void, Never>?

    private static let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let codes = codes(at: tick)
        VStack(spacing: 0) {
            Group {
                if accounts.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 4) {
                        ForEach(accounts) { account in
                            row(account, code: codes[account.id])
                        }
                    }
                    .padding(8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            Divider()
            footer
        }
        .frame(width: 300)
        .frame(minHeight: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
        }
        .onAppear { tick = Date() }
        .onReceive(Self.timer) { date in
            tick = date
        }
        .alert("重命名账户", isPresented: renamePresented) {
            TextField("名称", text: $renameText)
            Button("取消", role: .cancel) { renaming = nil }
            Button("保存") {
                if let account = renaming { onRename(account.id, renameText) }
                renaming = nil
            }
        } message: {
            Text("用空格分隔站点名与用户名。")
        }
        .alert("删除账户", isPresented: deletePresented, presenting: deleting) { account in
            Button("取消", role: .cancel) { deleting = nil }
            Button("删除", role: .destructive) {
                onDelete(account.id)
                deleting = nil
            }
        } message: { account in
            Text("确定要删除 \(account.name) 吗？此操作不可撤销")
        }
    }

    private var renamePresented: Binding<Bool> {
        Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })
    }

    private var deletePresented: Binding<Bool> {
        Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.badge.clock")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("暂无 TOTP 账户")
                .font(.headline)
                .foregroundStyle(.primary)
            Text("添加账户后，验证码会显示在这里。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("添加第一个账户", action: onAdd)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // 每秒只跨一次边界：整列表一次批量算码，不逐账户调用。
    private func codes(at date: Date) -> [String: OtpCodeResult] {
        let results = generateCodesBatch(
            accounts: accounts.map(\.params),
            unixTime: Int64(date.timeIntervalSince1970)
        )
        return Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0) })
    }

    private func row(_ account: TOTPAccount, code: OtpCodeResult?) -> some View {
        let remaining = Int(code?.remainingSeconds ?? 0)
        let hovering = hoveredID == account.id
        let parts = displayTitle(siteName: account.siteName, accountName: account.username)
        let warning = remaining <= 5 && code != nil
        let copied = copiedID == account.id
        return Button {
            copy(code?.code, for: account.id)
        } label: {
            HStack(spacing: 10) {
                Text(parts.title.first.map(String.init) ?? "?")
                    .font(.headline)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor.opacity(0.16), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(copied ? "已复制" : parts.title)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(.primary)
                    Text(parts.subtitle ?? " ")
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if let code {
                    Text(groupedCode(code.code, grouped: groupCodes))
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(warning ? Color.orange : Color.primary)
                }
                ring(remaining: remaining, fraction: Double(remaining) / Double(code?.period ?? 1), warning: warning)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(hovering ? Color.primary.opacity(0.08) : .clear)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { inside in
            hoveredID = inside ? account.id : (hoveredID == account.id ? nil : hoveredID)
        }
        .contextMenu {
            Button("复制验证码") { copy(code?.code, for: account.id) }
            Button("复制账号名") { clipboard.write(account.username) }
                .disabled(account.username.isEmpty)
            Divider()
            Button("重命名...") {
                renameText = account.name
                renaming = account
            }
            Button("删除账户", role: .destructive) { deleting = account }
        }
    }

    private func ring(remaining: Int, fraction: Double, warning: Bool) -> some View {
        ZStack {
            Circle().stroke(Color.secondary.opacity(0.25), lineWidth: 2)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(warning ? Color.orange : Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(remaining)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(warning ? Color.orange : Color.primary)
        }
        .frame(width: 28, height: 28)
    }

    private var footer: some View {
        HStack(spacing: 4) {
            Text("共 \(accounts.count) 个账户")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            FooterButton(systemName: "plus", action: onAdd)
            FooterButton(systemName: "gearshape", action: onSettings)
            FooterButton(systemName: "power") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func copy(_ code: String?, for id: String) {
        guard let code else { return }
        // 写入的始终是未分段验证码
        clipboard.write(code)
        copiedID = id
        let autoClear = clipboardAutoClear
        let delay = max(clipboardClearDelay, 2)
        copyResetTask?.cancel()
        copyResetTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            if copiedID == id { copiedID = nil }
            guard autoClear else { return }
            try? await Task.sleep(for: .seconds(delay - 2))
            guard !Task.isCancelled else { return }
            if shouldClearClipboard(current: clipboard.read(), copied: code) {
                clipboard.clear()
            }
        }
    }
}

private struct FooterButton: View {
    var systemName: String
    var action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .frame(width: 28, height: 24)
                .foregroundStyle(.primary)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(hovering ? Color.primary.opacity(0.08) : .clear)
                }
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

protocol Clipboard {
    func write(_ value: String)
    func read() -> String?
    func clear()
}

struct SystemClipboard: Clipboard {
    func write(_ value: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }

    func read() -> String? {
        NSPasteboard.general.string(forType: .string)
    }

    func clear() {
        NSPasteboard.general.clearContents()
    }
}
