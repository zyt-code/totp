package app.totp.core

private val ALPHABET = buildString {
    append(('A'..'Z').joinToString(""))
    append(('2'..'7').joinToString(""))
}

fun decodeBase32(text: String): ByteArray {
    val cleaned = text.uppercase().filter { !it.isWhitespace() && it != '-' }
    if (cleaned.isEmpty()) throw OtpException("invalid secret")
    var buffer = 0
    var bits = 0
    var padding = 0
    val output = ArrayList<Byte>()
    for (character in cleaned) {
        if (character == '=') {
            padding += 1
            continue
        }
        val value = ALPHABET.indexOf(character)
        if (padding != 0 || value < 0) throw OtpException("invalid secret")
        buffer = (buffer shl 5) or value
        bits += 5
        if (bits >= 8) {
            bits -= 8
            output += ((buffer shr bits) and 0xff).toByte()
        }
    }
    if ((padding != 0 && cleaned.length % 8 != 0) || output.isEmpty()) throw OtpException("invalid secret")
    return output.toByteArray()
}

fun encodeBase32(data: ByteArray): String {
    val output = StringBuilder()
    var buffer = 0
    var bits = 0
    for (byte in data) {
        buffer = (buffer shl 8) or (byte.toInt() and 0xff)
        bits += 8
        while (bits >= 5) {
            bits -= 5
            output.append(ALPHABET[(buffer shr bits) and 0x1f])
        }
    }
    if (bits > 0) output.append(ALPHABET[(buffer shl (5 - bits)) and 0x1f])
    return output.toString()
}
