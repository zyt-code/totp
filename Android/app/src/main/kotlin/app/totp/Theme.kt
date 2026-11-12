package app.totp

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

/** 蓝灰兜底配色，动态取色不可用时使用。 */
private val SlateLight = lightColorScheme(
    primary = Color(0xFF45647B),
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFFCBE6FF),
    onPrimaryContainer = Color(0xFF001E31),
    secondary = Color(0xFF52606B),
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFFD6E4F0),
    onSecondaryContainer = Color(0xFF0F1D28),
    background = Color(0xFFF7F9FB),
    onBackground = Color(0xFF191C1E),
    surface = Color(0xFFF7F9FB),
    onSurface = Color(0xFF191C1E),
    surfaceVariant = Color(0xFFDDE3E8),
    onSurfaceVariant = Color(0xFF41484D),
    outline = Color(0xFF71787D),
    outlineVariant = Color(0xFFC1C7CC),
    error = Color(0xFFBA1A1A),
)

private val SlateDark = darkColorScheme(
    primary = Color(0xFFA8C8E2),
    onPrimary = Color(0xFF0B344B),
    primaryContainer = Color(0xFF274B62),
    onPrimaryContainer = Color(0xFFCBE6FF),
    secondary = Color(0xFFBAC8D4),
    onSecondary = Color(0xFF24313B),
    secondaryContainer = Color(0xFF3A4751),
    onSecondaryContainer = Color(0xFFD6E4F0),
    background = Color(0xFF0F1417),
    onBackground = Color(0xFFDEE3E6),
    surface = Color(0xFF0F1417),
    onSurface = Color(0xFFDEE3E6),
    surfaceVariant = Color(0xFF41484D),
    onSurfaceVariant = Color(0xFFC1C7CC),
    outline = Color(0xFF8B9298),
    outlineVariant = Color(0xFF41484D),
    error = Color(0xFFFFB4AB),
)

/** 卡片与分组需要的容器层级，单独补上以便两种兜底配色一致。 */
internal fun fallbackScheme(dark: Boolean) = (if (dark) SlateDark else SlateLight).copy(
    surfaceContainerLowest = if (dark) Color(0xFF090F12) else Color(0xFFFFFFFF),
    surfaceContainerLow = if (dark) Color(0xFF171C1F) else Color(0xFFF1F4F7),
    surfaceContainer = if (dark) Color(0xFF1B2023) else Color(0xFFEBEEF1),
    surfaceContainerHigh = if (dark) Color(0xFF252B2E) else Color(0xFFE5E9EC),
    surfaceContainerHighest = if (dark) Color(0xFF303639) else Color(0xFFDFE3E6),
)

@Composable
fun TotpTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit,
) {
    val context = LocalContext.current
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        else -> fallbackScheme(darkTheme)
    }
    MaterialTheme(colorScheme = colorScheme, content = content)
}
