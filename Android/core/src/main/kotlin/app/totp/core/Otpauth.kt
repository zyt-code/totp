package app.totp.core

import java.net.URI
import java.net.URLDecoder
import java.net.URLEncoder

data class OtpauthFields(
    val name: String,
    val secret: String,
    val algorithm: HashAlgorithm,
    val digits: Int,
    val period: Int,
)

data class Account(
    val siteName: String,
    val username: String,
    val secret: ByteArray,
    val algorithm: HashAlgorithm,
    val digits: Int,
    val period: Int,
)

fun parseOtpauth(text: String): OtpauthFields {
    val uri = try {
        URI(text)
    } catch (_: Exception) {
        throw OtpException("invalid secret")
    }
    if (uri.scheme != "otpauth" || uri.host != "totp") throw OtpException("invalid secret")
    val query = (uri.rawQuery ?: "").split('&').mapNotNull { part ->
        if (part.isEmpty()) return@mapNotNull null
        val separator = part.indexOf('=')
        val key = if (separator < 0) part else part.substring(0, separator)
        val value = if (separator < 0) "" else part.substring(separator + 1)
        key to decode(value)
    }.toMap()
    val secret = query["secret"]?.takeIf { it.isNotEmpty() } ?: throw OtpException("invalid secret")
    val label = decode(uri.rawPath.removePrefix("/"))
    val labelParts = label.split(':', limit = 2).map { it.trim() }
    val issuer = query["issuer"]?.replace('+', ' ')?.trim()?.takeIf { it.isNotEmpty() }
    val account = (if (labelParts.size == 2) labelParts[1] else labelParts.firstOrNull())?.takeIf { it.isNotEmpty() }
    val labelIssuer = if (labelParts.size == 2) labelParts[0].takeIf { it.isNotEmpty() } else null
    val name = listOfNotNull(issuer ?: labelIssuer, account).joinToString(" ")
    return OtpauthFields(name, secret, algorithm(query["algorithm"]), digits(query["digits"]), period(query["period"]))
}

fun otpauthUri(account: Account): String {
    val label = if (account.username.isEmpty()) escape(account.siteName)
    else "${escape(account.siteName)}:${escape(account.username)}"
    val query = listOf(
        "secret=${encodeBase32(account.secret)}",
        "issuer=${escape(account.siteName)}",
        "algorithm=${account.algorithm.name}",
        "digits=${account.digits}",
        "period=${account.period}",
    ).joinToString("&")
    return "otpauth://totp/$label?$query"
}

fun otpauthBackup(accounts: List<Account>) = accounts.joinToString("\n", transform = ::otpauthUri)

data class ImportResult(val saved: Int, val skipped: Int)

fun classifyBackup(text: String): Pair<List<OtpauthFields>, Int> {
    val accepted = mutableListOf<OtpauthFields>()
    var skipped = 0
    text.lineSequence().map { it.trim() }.filter { it.isNotEmpty() }.forEach { line ->
        try {
            accepted += parseOtpauth(line)
        } catch (_: OtpException) {
            skipped += 1
        }
    }
    return accepted to skipped
}

private fun decode(text: String) = URLDecoder.decode(text, Charsets.UTF_8)

private fun escape(text: String) = URLEncoder.encode(text, Charsets.UTF_8).replace("+", "%20")

private fun algorithm(value: String?) = when (value?.uppercase()) {
    null, "SHA1" -> HashAlgorithm.SHA1
    "SHA256" -> HashAlgorithm.SHA256
    "SHA512" -> HashAlgorithm.SHA512
    else -> throw OtpException("invalid secret")
}

private fun digits(value: String?) = when (value) {
    null, "6" -> 6
    "8" -> 8
    else -> throw OtpException("invalid secret")
}

private fun period(value: String?): Int {
    if (value == null) return 30
    return value.toIntOrNull()?.takeIf { it > 0 } ?: throw OtpException("invalid secret")
}
