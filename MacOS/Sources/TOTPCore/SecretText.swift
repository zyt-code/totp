import Foundation

// core 只以字节交换密钥；手工录入和旧数据迁移需要的 Base32 文本转换走 core 的编解码导出，
// Swift 侧不再写第二份 Base32。
public enum SecretText {
    public static func decode(_ text: String) throws -> Data {
        try decodeBase32Secret(text: text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    public static func encode(_ data: Data) -> String {
        encodeBase32Secret(secret: data)
    }
}
