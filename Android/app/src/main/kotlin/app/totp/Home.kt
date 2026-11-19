package app.totp

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.outlined.QrCodeScanner
import androidx.compose.material.icons.rounded.QrCodeScanner
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.nestedscroll.NestedScrollConnection
import androidx.compose.ui.input.nestedscroll.NestedScrollSource
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.totp.core.ffi.OtpCodeResult
import app.totp.core.ffi.generateCodesBatch
import kotlinx.coroutines.delay

/** 莫兰迪色系，按服务商名称稳定取色。 */
private val MorandiPalette = listOf(
    Color(0xFF8FA3A8),
    Color(0xFFA39A8F),
    Color(0xFF9AA79B),
    Color(0xFFA89AA6),
    Color(0xFF9FA5B4),
    Color(0xFFB0A19B),
    Color(0xFF8EA6A1),
    Color(0xFFA9A28C),
)

internal fun morandiColor(name: String): Color =
    MorandiPalette[(name.hashCode() and Int.MAX_VALUE) % MorandiPalette.size]

/** 下拉超过该距离即进入搜索。 */
private val PullToSearchThreshold = 64.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(model: HomeModel, onScan: () -> Unit, onOpenSettings: () -> Unit) {
    val snackbar = remember { SnackbarHostState() }
    val listState = rememberLazyListState()
    var searching by remember { mutableStateOf(false) }
    var query by remember { mutableStateOf("") }
    var pendingRename by remember { mutableStateOf<StoredAccount?>(null) }
    var pendingDelete by remember { mutableStateOf<StoredAccount?>(null) }
    var copiedId by remember { mutableStateOf<String?>(null) }

    // 复制后短暂显示「已复制」，避免点了没反应。
    LaunchedEffect(copiedId) {
        if (copiedId != null) {
            delay(1_200)
            copiedId = null
        }
    }

    val focusRequester = remember { FocusRequester() }
    val keyboard = LocalSoftwareKeyboardController.current
    val focusManager = LocalFocusManager.current
    val haptics = LocalHapticFeedback.current

    // 每秒只跨一次边界：全部验证码一次算完。
    val codes = remember(model.accounts, model.now) {
        generateCodesBatch(model.accounts.map { it.toAccount() }, model.now).associateBy { it.id }
    }

    val visible = remember(model.accounts, query) {
        if (query.isBlank()) model.accounts
        else model.accounts.filter {
            it.siteName.contains(query, ignoreCase = true) || it.username.contains(query, ignoreCase = true)
        }
    }

    val closeSearch = {
        searching = false
        query = ""
        keyboard?.hide()
        focusManager.clearFocus()
    }

    // 进入搜索态后自动聚焦并拉起输入法；等一帧确保搜索框已完成布局。
    LaunchedEffect(searching) {
        if (searching) {
            withFrameNanos { }
            focusRequester.requestFocus()
            keyboard?.show()
        }
    }

    // 搜索态下系统返回键先退出搜索，而不是退出应用。
    BackHandler(enabled = searching) { closeSearch() }

    val openSearch = rememberUpdatedState {
        if (!searching) {
            searching = true
            haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
        }
    }
    val threshold = with(LocalDensity.current) { PullToSearchThreshold.toPx() }
    var pulled by remember { mutableFloatStateOf(0f) }
    val pullToSearch = remember(listState, threshold) {
        object : NestedScrollConnection {
            override fun onPostScroll(
                consumed: Offset,
                available: Offset,
                source: NestedScrollSource,
            ): Offset {
                val atTop = listState.firstVisibleItemIndex == 0 && listState.firstVisibleItemScrollOffset == 0
                if (!atTop || available.y < 0f) {
                    pulled = 0f
                } else if (available.y > 0f) {
                    pulled += available.y
                    if (pulled >= threshold) {
                        pulled = 0f
                        openSearch.value()
                    }
                }
                return Offset.Zero
            }
        }
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent),
                title = {
                    AnimatedContent(
                        targetState = searching,
                        transitionSpec = { fadeIn(tween(180)) togetherWith fadeOut(tween(120)) },
                        label = "search-bar",
                    ) { active ->
                        if (active) {
                            SearchField(query, { query = it }, focusRequester)
                        } else {
                            Text("TOTP", fontWeight = FontWeight.SemiBold)
                        }
                    }
                },
                navigationIcon = {
                    if (searching) {
                        IconButton(onClick = closeSearch) {
                            Icon(Icons.Filled.Close, contentDescription = "关闭搜索")
                        }
                    }
                },
                actions = {
                    if (!searching) {
                        IconButton(onClick = { searching = true }) {
                            Icon(Icons.Filled.Search, contentDescription = "搜索")
                        }
                        IconButton(onClick = onOpenSettings) {
                            Icon(Icons.Filled.Settings, contentDescription = "设置")
                        }
                    }
                },
            )
        },
        snackbarHost = { SnackbarHost(snackbar) },
        floatingActionButton = {
            FloatingActionButton(
                onClick = onScan,
                containerColor = MaterialTheme.colorScheme.primaryContainer,
                contentColor = MaterialTheme.colorScheme.onPrimaryContainer,
            ) {
                Icon(Icons.Rounded.QrCodeScanner, contentDescription = "扫码添加")
            }
        },
    ) { padding ->
        when {
            model.accounts.isEmpty() ->
                EmptyState("暂无 TOTP 账户", "扫描二维码即可添加", onScan, Modifier.padding(padding))
            visible.isEmpty() ->
                EmptyState("没有匹配的账户", "换个关键词试试", null, Modifier.padding(padding))
            else -> LazyColumn(
                state = listState,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .nestedScroll(pullToSearch),
                contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 96.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(visible, key = { it.id }) { account ->
                    AccountCard(
                        modifier = Modifier.animateItem(),
                        account = account,
                        grouped = model.grouped,
                        code = codes[account.id],
                        copied = copiedId == account.id,
                        onClick = {
                            model.copy(account)
                            copiedId = account.id
                        },
                        onLongClick = { pendingRename = account },
                    )
                }
            }
        }
    }

    pendingRename?.let { account ->
        AccountMenu(
            account,
            onDismiss = { pendingRename = null },
            onRename = { name ->
                pendingRename = null
                if (!model.rename(account, name)) model.report("名称不能为空")
            },
            onDelete = { pendingDelete = account; pendingRename = null },
        )
    }
    pendingDelete?.let { account ->
        AlertDialog(
            onDismissRequest = { pendingDelete = null },
            confirmButton = { TextButton(onClick = { model.delete(account); pendingDelete = null }) { Text("删除") } },
            dismissButton = { TextButton(onClick = { pendingDelete = null }) { Text("取消") } },
            text = { Text("确定要删除 ${account.displayName} 吗？此操作不可撤销") },
        )
    }
    LaunchedEffect(model.message) {
        model.message?.let { snackbar.showSnackbar(it); model.consumeMessage() }
    }
}

@Composable
private fun SearchField(query: String, onChange: (String) -> Unit, focusRequester: FocusRequester) {
    BasicTextField(
        value = query,
        onValueChange = onChange,
        singleLine = true,
        textStyle = MaterialTheme.typography.titleMedium.copy(color = MaterialTheme.colorScheme.onSurface),
        cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
        modifier = Modifier.fillMaxWidth().focusRequester(focusRequester),
        decorationBox = { inner ->
            if (query.isEmpty()) {
                Text(
                    "搜索账户",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            inner()
        },
    )
}

@Composable
private fun EmptyState(title: String, subtitle: String, onScan: (() -> Unit)?, modifier: Modifier = Modifier) {
    Column(
        modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Box(
            Modifier.size(72.dp).clip(CircleShape).background(MaterialTheme.colorScheme.surfaceContainerHigh),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                Icons.Outlined.QrCodeScanner,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        Spacer(Modifier.height(16.dp))
        Text(title, style = MaterialTheme.typography.titleMedium)
        Spacer(Modifier.height(4.dp))
        Text(subtitle, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        if (onScan != null) {
            Spacer(Modifier.height(20.dp))
            Button(onClick = onScan) { Text("扫描二维码") }
        }
    }
}

@Composable
private fun AccountCard(
    modifier: Modifier = Modifier,
    account: StoredAccount,
    grouped: Boolean,
    code: OtpCodeResult?,
    copied: Boolean,
    onClick: () -> Unit,
    onLongClick: () -> Unit,
) {
    val (title, subtitle) = account.labels
    val period = (code?.period ?: account.period).toLong()
    val left = (code?.remainingSeconds ?: 0).toLong()
    val accent by animateColorAsState(
        if (expiring(left)) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary,
        label = "countdown-color",
    )

    Card(
        modifier = modifier.fillMaxWidth().combinedClickable(onClick = onClick, onLongClick = onLongClick),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
    ) {
        Row(Modifier.padding(horizontal = 16.dp, vertical = 14.dp), verticalAlignment = Alignment.CenterVertically) {
            InitialBadge(account.siteName)
            Column(Modifier.weight(1f).padding(horizontal = 14.dp)) {
                Text(
                    title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.MiddleEllipsis,
                )
                if (!subtitle.isNullOrEmpty()) {
                    Text(
                        subtitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.MiddleEllipsis,
                    )
                }
                Spacer(Modifier.height(6.dp))
                val codeStyle = MaterialTheme.typography.headlineMedium.copy(
                    fontFamily = FontFamily.Monospace,
                    letterSpacing = 1.5.sp,
                    fontWeight = FontWeight.Medium,
                )
                AnimatedContent(
                    targetState = copied,
                    transitionSpec = { fadeIn(tween(120)) togetherWith fadeOut(tween(120)) },
                    label = "copy-feedback",
                ) { justCopied ->
                    if (justCopied) {
                        Text("已复制", style = codeStyle, color = MaterialTheme.colorScheme.primary)
                    } else {
                        Text(formatCode(code?.code.orEmpty(), grouped), style = codeStyle, color = accent)
                    }
                }
            }
            CountdownRing(left, period, accent)
        }
    }
}

@Composable
private fun InitialBadge(name: String) {
    Box(
        Modifier.size(42.dp).clip(CircleShape).background(morandiColor(name)),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            name.take(1).uppercase(),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = Color.White,
        )
    }
}

@Composable
private fun CountdownRing(secondsLeft: Long, period: Long, color: Color) {
    val fraction = (secondsLeft.toFloat() / period).coerceIn(0f, 1f)
    Box(Modifier.size(36.dp), contentAlignment = Alignment.Center) {
        Canvas(Modifier.fillMaxSize()) {
            val stroke = 3.dp.toPx()
            drawArc(
                color = color.copy(alpha = 0.16f),
                startAngle = -90f,
                sweepAngle = 360f,
                useCenter = false,
                style = Stroke(stroke, cap = StrokeCap.Round),
            )
            drawArc(
                color = color,
                startAngle = -90f,
                sweepAngle = 360f * fraction,
                useCenter = false,
                style = Stroke(stroke, cap = StrokeCap.Round),
            )
        }
        Text(
            secondsLeft.toString(),
            style = MaterialTheme.typography.labelSmall,
            fontFamily = FontFamily.Monospace,
            color = color,
        )
    }
}

@Composable
private fun AccountMenu(account: StoredAccount, onDismiss: () -> Unit, onRename: (String) -> Unit, onDelete: () -> Unit) {
    var renaming by remember { mutableStateOf(false) }
    var name by remember { mutableStateOf(account.displayName) }
    if (renaming) {
        AlertDialog(
            onDismissRequest = onDismiss,
            confirmButton = { TextButton(onClick = { onRename(name) }) { Text("保存") } },
            dismissButton = { TextButton(onClick = onDismiss) { Text("取消") } },
            text = {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    singleLine = true,
                    label = { Text("名称") },
                )
            },
        )
    } else {
        AlertDialog(
            onDismissRequest = onDismiss,
            confirmButton = { TextButton(onClick = { renaming = true }) { Text("重命名") } },
            dismissButton = { TextButton(onClick = onDelete) { Text("删除") } },
            text = { Text(account.displayName) },
        )
    }
}

class HomeModel(
    val accounts: List<StoredAccount>,
    val grouped: Boolean,
    val autoClear: Boolean,
    val allowScreenshots: Boolean,
    val now: Long,
    val message: String?,
    val copy: (StoredAccount) -> Unit,
    val rename: (StoredAccount, String) -> Boolean,
    val delete: (StoredAccount) -> Unit,
    val setAutoClear: (Boolean) -> Unit,
    val setGrouped: (Boolean) -> Unit,
    val setAllowScreenshots: (Boolean) -> Unit,
    val export: () -> Unit,
    val import: () -> Unit,
    val consumeMessage: () -> Unit,
    val report: (String) -> Unit,
)

fun formatCode(code: String, grouped: Boolean) =
    if (grouped && code.length == 6) "${code.take(3)} ${code.drop(3)}" else code

fun expiring(secondsLeft: Long) = secondsLeft <= 5

fun shouldClear(copied: String, current: String?) = current == copied
