#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

// 1024 母图，主图标 824 居中，留 100 的安全边距。
let canvasSize: CGFloat = 1024
let tileSide: CGFloat = 824
let tileCornerRadius: CGFloat = 185
// 前景严格收在中心 56% 区域内，避免贴边。
let ringDiameter: CGFloat = 492

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

struct AppIconView: View {
    var body: some View {
        ZStack {
            Color.clear
            tile
                .frame(width: tileSide, height: tileSide)
        }
        .frame(width: canvasSize, height: canvasSize)
    }

    private var tile: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x3B82F6), Color(hex: 0x1D4ED8)],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color.white.opacity(0.22), Color.white.opacity(0)],
                center: UnitPoint(x: 0.28, y: 0.16),
                startRadius: 0,
                endRadius: 640
            )
            foreground
        }
        .clipShape(RoundedRectangle(cornerRadius: tileCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: tileCornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 2)
        }
    }

    private var foreground: some View {
        ZStack {
            // 底层完整圆环轨道
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 28)
                .frame(width: ringDiameter, height: ringDiameter)
            // 上层 270 度进度弧
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 28, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: ringDiameter, height: ringDiameter)
            Image(systemName: "lock.fill")
                .font(.system(size: 220, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
        }
    }
}

@MainActor
func renderBaseImage() -> CGImage? {
    let renderer = ImageRenderer(content: AppIconView())
    renderer.scale = 1
    renderer.isOpaque = false
    return renderer.cgImage
}

func scaled(_ image: CGImage, to pixels: Int) -> CGImage? {
    guard let space = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(
              data: nil,
              width: pixels,
              height: pixels,
              bitsPerComponent: 8,
              bytesPerRow: 0,
              space: space,
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          ) else { return nil }
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: pixels, height: pixels))
    return context.makeImage()
}

func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "icon", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法创建 PNG 输出 \(url.lastPathComponent)"])
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(domain: "icon", code: 2, userInfo: [NSLocalizedDescriptionKey: "写入 PNG 失败 \(url.lastPathComponent)"])
    }
}

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let resources = root.appendingPathComponent("Resources", isDirectory: true)
let iconset = resources.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let icns = resources.appendingPathComponent("AppIcon.icns")

let entries: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

do {
    let fileManager = FileManager.default
    try? fileManager.removeItem(at: iconset)
    try fileManager.createDirectory(at: iconset, withIntermediateDirectories: true)

    guard let base = MainActor.assumeIsolated({ renderBaseImage() }) else {
        FileHandle.standardError.write(Data("SwiftUI 渲染 1024 母图失败\n".utf8))
        exit(1)
    }

    for (name, pixels) in entries {
        guard let image = scaled(base, to: pixels) else {
            FileHandle.standardError.write(Data("缩放失败: \(name)\n".utf8))
            exit(1)
        }
        try writePNG(image, to: iconset.appendingPathComponent(name))
    }

    let iconutil = Process()
    iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    iconutil.arguments = ["-c", "icns", iconset.path, "-o", icns.path]
    try iconutil.run()
    iconutil.waitUntilExit()
    guard iconutil.terminationStatus == 0 else {
        FileHandle.standardError.write(Data("iconutil 生成 icns 失败\n".utf8))
        exit(1)
    }

    try fileManager.removeItem(at: iconset)
    print("已生成 \(icns.path)")
} catch {
    FileHandle.standardError.write(Data("生成图标出错: \(error.localizedDescription)\n".utf8))
    exit(1)
}
