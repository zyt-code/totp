import AppKit
import SwiftUI
import TOTPCore

struct AddAccountForm: View {
    @Binding var displayName: String
    @Binding var secret: String
    @Binding var algorithm: HashAlgorithm
    @Binding var digits: Int
    @Binding var period: Int
    var error: String?
    var onSave: () -> Void
    var onCancel: () -> Void
    var onScan: () -> Void
    var onHeight: (Double) -> Void = { _ in }

    @State private var advanced = false
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("新增验证码")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Text("手动输入或扫描二维码以绑定动态口令")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 0) {
                TextField("例如 github.com 或 [邮箱]", text: $displayName)
                    .textFieldStyle(.plain)
                    .focused($nameFocused)
                    .padding(10)
                Divider()
                HStack(spacing: 8) {
                    TextField("Secret", text: $secret)
                        .textFieldStyle(.plain)
                    Button("粘贴", action: paste)
                        .buttonStyle(.borderless)
                    Button(action: onScan) {
                        Image(systemName: "qrcode.viewfinder")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(10)
            }
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            if let message = secretMessage ?? error {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            DisclosureGroup("高级选项 (算法、位数与周期)", isExpanded: $advanced) {
                Picker("算法", selection: $algorithm) {
                    Text("SHA-1").tag(HashAlgorithm.sha1)
                    Text("SHA-256").tag(HashAlgorithm.sha256)
                    Text("SHA-512").tag(HashAlgorithm.sha512)
                }
                Picker("位数", selection: $digits) {
                    Text("6").tag(6)
                    Text("8").tag(8)
                }
                Stepper("周期 \(period) 秒", value: $period, in: 1...120)
            }
            HStack {
                Spacer()
                Button("取消", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("添加", action: onSave)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
            }
        }
        .padding(20)
        .frame(width: 380)
        .fixedSize(horizontal: true, vertical: true)
        .background(.regularMaterial)
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: FormHeightKey.self, value: proxy.size.height)
            }
        }
        .onPreferenceChange(FormHeightKey.self, perform: onHeight)
        .onChange(of: secret) { _, newValue in
            applyOtpauthIfPresent(newValue)
        }
        .onAppear { nameFocused = true }
    }

    private var canSave: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && secretMessage == nil && !secret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var secretMessage: String? {
        let trimmed = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return (try? decodeBase32(secret)) == nil ? "Secret 不是有效的 Base32" : nil
    }

    private func paste() {
        guard let value = NSPasteboard.general.string(forType: .string) else { return }
        secret = value
        applyOtpauthIfPresent(value)
    }

    // 仅在能解析出合法 Secret 时改写表单，避免输入过程中的半成品 URI 打断编辑。
    private func applyOtpauthIfPresent(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.lowercased().hasPrefix("otpauth://"),
              let fields = try? parseOtpauth(trimmed),
              (try? decodeBase32(fields.secret)) != nil else { return }
        if displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            displayName = fields.name
        }
        secret = fields.secret
        algorithm = fields.algorithm
        digits = fields.digits
        period = fields.period
    }
}

private struct FormHeightKey: PreferenceKey {
    static let defaultValue = 0.0
    static func reduce(value: inout Double, nextValue: () -> Double) {
        value = max(value, nextValue())
    }
}
