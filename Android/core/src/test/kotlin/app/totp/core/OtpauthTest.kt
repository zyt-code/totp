package app.totp.core

import org.junit.Assert.assertEquals
import org.junit.Test

class OtpauthTest {
    private val canonical = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"

    @Test
    fun fullUri() {
        val parsed = parseOtpauth(
            "otpauth://totp/GitHub:ada?secret=GEZDGNBV&algorithm=SHA256&digits=8&period=45",
        )
        assertEquals(OtpauthFields("GitHub ada", "GEZDGNBV", HashAlgorithm.SHA256, 8, 45), parsed)
    }

    @Test
    fun defaults() {
        val parsed = parseOtpauth("otpauth://totp/GitHub?secret=GEZDGNBV")
        assertEquals(HashAlgorithm.SHA1, parsed.algorithm)
        assertEquals(6, parsed.digits)
        assertEquals(30, parsed.period)
        assertEquals("GitHub", parsed.name)
    }

    @Test
    fun decodesPlusAsSpace() {
        val parsed = parseOtpauth("otpauth://totp/Spot%20Auth%20Lab:test%40spot-auth.app?secret=[密钥]")
        assertEquals("Spot Auth Lab " + "test" + "@" + "spot-auth.app", parsed.name)
    }

    @Test
    fun rejectsInvalidUri() {
        fails { parseOtpauth("otpauth://totp/GitHub") }
        fails { parseOtpauth("otpauth://hotp/GitHub?secret=GEZDGNBV") }
        fails { parseOtpauth("otpauth://totp/GitHub?secret=GEZDGNBV&algorithm=SHA384") }
        fails { parseOtpauth("otpauth://totp/GitHub?secret=GEZDGNBV&digits=7") }
        fails { parseOtpauth("otpauth://totp/GitHub?secret=GEZDGNBV&period=0") }
    }

    @Test
    fun uriRoundTrips() {
        val account = Account("GitHub", "ada", decodeBase32(canonical), HashAlgorithm.SHA256, 8, 45)
        val parsed = parseOtpauth(otpauthUri(account))
        assertEquals(canonical, parsed.secret)
        assertEquals(HashAlgorithm.SHA256, parsed.algorithm)
        assertEquals(8, parsed.digits)
        assertEquals(45, parsed.period)
    }

    @Test
    fun importSkipsBadLines() {
        val good = otpauthUri(Account("GitHub", "ada", decodeBase32(canonical), HashAlgorithm.SHA1, 6, 30))
        val (accepted, skipped) = classifyBackup("$good\nnot a uri\n$good")
        assertEquals(2, accepted.size)
        assertEquals(1, skipped)
    }
}
