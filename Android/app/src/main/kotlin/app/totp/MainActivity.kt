package app.totp

import android.Manifest
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Color as AndroidColor
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.result.contract.ActivityResultContracts.CreateDocument
import androidx.activity.result.contract.ActivityResultContracts.OpenDocument
import androidx.activity.result.contract.ActivityResultContracts.PickVisualMedia
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.lifecycleScope
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import app.totp.core.Secret
import app.totp.core.classifyBackup
import app.totp.core.otpauthBackup
import app.totp.core.totp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val preferences = Preferences(this)
        applySecureWindow(preferences)
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.auto(AndroidColor.TRANSPARENT, AndroidColor.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.auto(AndroidColor.TRANSPARENT, AndroidColor.TRANSPARENT),
        )
        val store = AccountStore.create(this)
        val reader = BarcodeReader()
        setContent { TotpTheme { App(store, preferences, reader) } }
    }

    /** 偏好一变就生效，不需要重启。默认开启防截屏。 */
    private fun applySecureWindow(preferences: Preferences) {
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        lifecycleScope.launch {
            preferences.values.collect { settings ->
                if (settings.allowScreenshots) {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
            }
        }
    }
}

private object Routes {
    const val Home = "home"
    const val Scan = "scan"
    const val Settings = "settings"
}

@Composable
private fun App(store: AccountStore, preferences: Preferences, reader: BarcodeReader) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val navController = rememberNavController()
    val settings by preferences.values.collectAsStateWithLifecycle(
        Settings(autoClear = true, grouped = true, allowScreenshots = false),
    )
    var accounts by remember { mutableStateOf<List<StoredAccount>>(emptyList()) }
    var now by remember { mutableLongStateOf(System.currentTimeMillis() / 1000) }
    var message by remember { mutableStateOf<String?>(null) }
    var confirmExport by remember { mutableStateOf(false) }

    suspend fun reload() { accounts = store.accounts() }
    LaunchedEffect(Unit) { reload() }
    LaunchedEffect(Unit) { while (true) { delay(1000); now = System.currentTimeMillis() / 1000 } }

    fun save(result: CaptureResult) {
        when (result) {
            is CaptureResult.Saved -> scope.launch {
                store.add(result.fields)
                reload()
                context.vibrate()
                navController.popBackStack()
            }
            is CaptureResult.Rejected -> message = result.reason
        }
    }

    val gallery = rememberLauncherForActivityResult(PickVisualMedia()) { uri ->
        if (uri == null) return@rememberLauncherForActivityResult
        scope.launch { save(acceptPayloads(reader.read(context, uri))) }
    }
    val exportFile = rememberLauncherForActivityResult(CreateDocument("text/plain")) { uri ->
        if (uri == null) return@rememberLauncherForActivityResult
        context.contentResolver.openOutputStream(uri)?.use { stream ->
            stream.write(backupText(accounts).toByteArray())
        }
    }
    val importFile = rememberLauncherForActivityResult(OpenDocument()) { uri ->
        if (uri == null) return@rememberLauncherForActivityResult
        scope.launch {
            val text = context.contentResolver.openInputStream(uri)?.bufferedReader()?.readText().orEmpty()
            val (accepted, skipped) = classifyBackup(text)
            accepted.forEach { store.add(it) }
            reload()
            message = "保存 ${accepted.size} 个，跳过 $skipped 行"
        }
    }
    val cameraPermission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) navController.navigate(Routes.Scan) { launchSingleTop = true } else message = "没有相机权限，仍可从相册选择"
    }
    fun openScan() {
        val granted = ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        if (granted) navController.navigate(Routes.Scan) { launchSingleTop = true } else cameraPermission.launch(Manifest.permission.CAMERA)
    }
    fun pickImage() = gallery.launch(PickVisualMediaRequest(PickVisualMedia.ImageOnly))

    val model = HomeModel(
        accounts = accounts,
        grouped = settings.grouped,
        autoClear = settings.autoClear,
        allowScreenshots = settings.allowScreenshots,
        now = now,
        message = message,
        copy = { account -> copyCode(context, account, now, settings.autoClear, scope) },
        rename = { account, name ->
            val accepted = name.trim().isNotEmpty()
            if (accepted) scope.launch { store.rename(account.id, name); reload() }
            accepted
        },
        delete = { account -> scope.launch { store.delete(account.id); reload() } },
        setAutoClear = { scope.launch { preferences.setAutoClear(it) } },
        setGrouped = { scope.launch { preferences.setGrouped(it) } },
        setAllowScreenshots = { scope.launch { preferences.setAllowScreenshots(it) } },
        export = { confirmExport = true },
        import = { importFile.launch(arrayOf("text/plain")) },
        consumeMessage = { message = null },
        report = { message = it },
    )

    NavHost(
        navController = navController,
        startDestination = Routes.Home,
        enterTransition = { slideInHorizontally(tween(240)) { it / 6 } + fadeIn(tween(240)) },
        exitTransition = { fadeOut(tween(200)) },
        popEnterTransition = { fadeIn(tween(240)) },
        popExitTransition = { slideOutHorizontally(tween(200)) { it / 6 } + fadeOut(tween(200)) },
    ) {
        composable(Routes.Home) {
            HomeScreen(
                model = model,
                onScan = ::openScan,
                onOpenSettings = { navController.navigate(Routes.Settings) { launchSingleTop = true } },
            )
        }
        composable(Routes.Scan) {
            ScanScreen(
                onResult = ::save,
                onPickImage = ::pickImage,
                onBack = { navController.popBackStack() },
            )
        }
        composable(Routes.Settings) {
            SettingsScreen(model = model, onBack = { navController.popBackStack() })
        }
    }

    if (confirmExport) {
        AlertDialog(
            onDismissRequest = { confirmExport = false },
            confirmButton = {
                TextButton(onClick = {
                    confirmExport = false
                    exportFile.launch("totp-backup.txt")
                }) { Text("导出") }
            },
            dismissButton = {
                TextButton(onClick = { confirmExport = false }) { Text("取消") }
            },
            text = { Text("备份包含密钥，只写入你选择的位置。") },
        )
    }
}

private fun copyCode(context: Context, account: StoredAccount, now: Long, autoClear: Boolean, scope: kotlinx.coroutines.CoroutineScope) {
    val code = totp(Secret(account.secret), now, account.algorithm, account.digits, account.period.toLong())
    val clipboard = context.getSystemService(ClipboardManager::class.java)
    clipboard.setPrimaryClip(ClipData.newPlainText("totp", code))
    if (!autoClear) return
    scope.launch {
        delay(30_000)
        val current = clipboard.primaryClip?.getItemAt(0)?.text?.toString()
        if (!shouldClear(code, current)) return@launch
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            clipboard.clearPrimaryClip()
        } else {
            clipboard.setPrimaryClip(ClipData.newPlainText("", ""))
        }
    }
}

private fun backupText(accounts: List<StoredAccount>) = otpauthBackup(accounts.map { it.toAccount() })

private fun Context.vibrate() {
    getSystemService(Vibrator::class.java).vibrate(VibrationEffect.createOneShot(40, VibrationEffect.DEFAULT_AMPLITUDE))
}
