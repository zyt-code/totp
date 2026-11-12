package app.totp.core

import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

enum class HashAlgorithm { SHA1, SHA256, SHA512 }

class OtpException(message: String) : Exception(message)

class Secret(val bytes: ByteArray) {
    override fun toString() = "Secret(<redacted>)"
}

fun totp(
    secret: Secret,
    time: Long,
    algorithm: HashAlgorithm,
    digits: Int,
    period: Long = 30,
): String {
    if (period <= 0) throw OtpException("invalid period")
    return hotp(secret, time / period, algorithm, digits)
}

fun hotp(secret: Secret, counter: Long, algorithm: HashAlgorithm, digits: Int): String {
    if (secret.bytes.isEmpty()) throw OtpException("empty secret")
    if (counter < 0) throw OtpException("negative counter")
    if (digits != 6 && digits != 8) throw OtpException("invalid digits")
    val message = ByteArray(8)
    var value = counter
    for (index in 7 downTo 0) {
        message[index] = value.toByte()
        value = value ushr 8
    }
    val mac = hmac(algorithm, secret.bytes, message)
    val offset = mac.last().toInt() and 0x0f
    val binary = (mac[offset].toInt() and 0x7f shl 24) or
        (mac[offset + 1].toInt() and 0xff shl 16) or
        (mac[offset + 2].toInt() and 0xff shl 8) or
        (mac[offset + 3].toInt() and 0xff)
    val modulus = if (digits == 6) 1_000_000 else 100_000_000
    return (binary % modulus).toString().padStart(digits, '0')
}

private fun hmac(algorithm: HashAlgorithm, key: ByteArray, message: ByteArray): ByteArray {
    val name = when (algorithm) {
        HashAlgorithm.SHA1 -> "HmacSHA1"
        HashAlgorithm.SHA256 -> "HmacSHA256"
        HashAlgorithm.SHA512 -> "HmacSHA512"
    }
    return Mac.getInstance(name).apply { init(SecretKeySpec(key, name)) }.doFinal(message)
}
