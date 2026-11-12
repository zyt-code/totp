package app.totp.core

/**
 * 把账户名称拆成站点与账号。
 * 优先按第一个冒号拆（"OpenAI:me@x.com"），否则按第一个空格拆；
 * 剩余部分若重复了同一个账号（"me@x.com me@x.com"），只保留一份。
 */
fun splitName(name: String): Pair<String, String> {
    val trimmed = name.trim()
    if (trimmed.isEmpty()) return "" to ""
    val colon = trimmed.indexOf(':')
    val (site, rest) = if (colon > 0) {
        trimmed.substring(0, colon).trim() to trimmed.substring(colon + 1).trim()
    } else {
        val parts = trimmed.split(' ', limit = 2)
        parts[0] to parts.getOrElse(1) { "" }.trim()
    }
    val tokens = rest.split(' ').filter { it.isNotEmpty() }
    val account = if (tokens.size >= 2 && tokens.all { it == tokens[0] }) tokens[0] else rest
    return site to account
}

/**
 * 卡片上真正要显示的主标题与副标题。
 * 兼容历史数据：站点里带着 "Issuer:Account"，而账号列里又是同一个账号时，不再重复显示。
 */
fun accountLabels(siteName: String, username: String): Pair<String, String> {
    val (site, implied) = splitName(siteName)
    val account = when {
        username.isBlank() -> implied
        implied.isBlank() || username == implied -> username
        else -> username
    }
    return site to account
}
