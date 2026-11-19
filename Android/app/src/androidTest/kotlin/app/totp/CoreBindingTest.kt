package app.totp

import android.util.Base64
import android.util.Log
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.totp.core.ffi.AccountParams
import app.totp.core.ffi.CoreException
import app.totp.core.ffi.HashAlgorithm
import app.totp.core.ffi.exportBackupJson
import app.totp.core.ffi.generateCode
import app.totp.core.ffi.generateCodesBatch
import app.totp.core.ffi.importBackupJson
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith

/**
 * 绑定冒烟测试：能走到这里就说明 JNA 从 APK 里加载了 libtotp_core.so。
 * 算法向量本身归 `core/` 的 cargo test，这里只验证跨边界一次。
 */
@RunWith(AndroidJUnit4::class)
class CoreBindingTest {
    private fun rfcAccount() = AccountParams(
        id = "1",
        issuer = "GitHub",
        accountName = "ada",
        secret = "12345678901234567890".toByteArray(),
        algorithm = HashAlgorithm.SHA1,
        digits = 8,
        period = 30,
    )

    @Test
    fun generatesRfc6238Vector() {
        // RFC 6238 附录 B：T=59、SHA-1、8 位
        assertEquals("94287082", generateCode(rfcAccount(), 59).code)
    }

    @Test
    fun backupJsonRoundTrips() {
        val json = exportBackupJson(listOf(rfcAccount()))
        assertTrue(json, json.contains("\"format\": \"totp-backup\""))
        assertTrue(json, json.contains("\"version\": 2"))

        val imported = importBackupJson(json)
        assertEquals(0, imported.skipped)
        val restored = imported.accounts.single()
        assertEquals("GitHub", restored.issuer)
        assertEquals("ada", restored.accountName)
        assertEquals("12345678901234567890", String(restored.secret))
        assertEquals(HashAlgorithm.SHA1, restored.algorithm)
        assertEquals(8, restored.digits)
        assertEquals(30, restored.period)
    }

    @Test
    fun linePerUriTextIsRejected() {
        try {
            importBackupJson("otpauth://totp/GitHub:ada?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ")
            fail("1.0 的行文本必须被拒绝")
        } catch (error: CoreException.BackupFormat) {
            assertTrue(error.v1, error.v1.contains("JSON"))
        }
    }

    @Test
    fun captureAcceptsOneOtpauthUri() {
        val result = acceptPayloads(listOf("otpauth://totp/GitHub:ada?secret=GEZDGNBV"))
        assertEquals("GitHub", (result as CaptureResult.Saved).account.issuer)
    }

    /** 跨端指纹：与 macOS CoreBindingTests.crossPlatformFingerprint 用完全相同的输入，输出逐字比对。 */
    @Test
    fun crossPlatformFingerprint() {
        val secret = "12345678901234567890".toByteArray()
        val accounts = listOf(
            AccountParams("a", "GitHub", "ada", secret, HashAlgorithm.SHA1, 6, 30),
            AccountParams("b", "阿里云", "", secret, HashAlgorithm.SHA512, 8, 60),
        )
        val parts = mutableListOf<String>()
        for (time in listOf(59L, 1_111_111_109L)) {
            generateCodesBatch(accounts, time).sortedBy { it.id }.forEach { parts += "${it.id}:${it.code}" }
        }
        val json = exportBackupJson(accounts)
        Log.i("XPLAT", "codes=${parts.joinToString(",")}")
        Log.i("XPLAT", "backup_b64=${Base64.encodeToString(json.toByteArray(), Base64.NO_WRAP)}")
    }
}
