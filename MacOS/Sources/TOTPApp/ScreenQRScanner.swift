import AppKit
import CoreGraphics
import ScreenCaptureKit
import TOTPCore
import Vision

enum ScreenScanError: Error {
    case permission
    case capture
    case none
    case many
    case invalid
}

@MainActor
enum ScreenQRScanner {
    static func scan() async throws -> ParsedAccount {
        guard CGPreflightScreenCaptureAccess() else {
            promptForPermission()
            throw ScreenScanError.permission
        }
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        var payloads: [String] = []
        for display in content.displays { payloads += try await capture(display) }
        let parsed = payloads.compactMap { try? parseOtpauthUri(uri: $0) }
        guard parsed.count == 1 else {
            throw parsed.isEmpty ? (payloads.isEmpty ? ScreenScanError.none : ScreenScanError.invalid) : ScreenScanError.many
        }
        return parsed[0]
    }

    private static func capture(_ display: SCDisplay) async throws -> [String] {
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = display.height
        config.showsCursor = false
        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        try VNImageRequestHandler(cgImage: image).perform([request])
        return (request.results ?? []).compactMap(\.payloadStringValue)
    }

    private static func promptForPermission() {
        let alert = NSAlert()
        alert.messageText = "需要屏幕录制权限"
        alert.informativeText = "请在系统设置的隐私与安全性中允许 TOTP 录制屏幕。授权后需要重新打开应用。"
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "取消")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
    }
}
