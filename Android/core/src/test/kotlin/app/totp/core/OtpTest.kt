package app.totp.core

import org.junit.Assert.assertEquals
import org.junit.Test

class OtpTest {
    private val seed20 = "12345678901234567890".toByteArray()
    private val seed32 = "12345678901234567890".repeat(2).take(32).toByteArray()
    private val seed64 = "12345678901234567890".repeat(4).take(64).toByteArray()

    @Test
    fun hotpRfc4226() {
        val secret = Secret(seed20)
        assertEquals("755224", hotp(secret, 0, HashAlgorithm.SHA1, 6))
        assertEquals("84755224", hotp(secret, 0, HashAlgorithm.SHA1, 8))
    }

    @Test
    fun hotpSha256AndSha512() {
        assertEquals("084774", hotp(Secret(seed32), 37_037_036, HashAlgorithm.SHA256, 6))
        assertEquals("943326", hotp(Secret(seed64), 37_037_037, HashAlgorithm.SHA512, 6))
    }

    @Test
    fun hotpRejectsInvalidInput() {
        fails { hotp(Secret(ByteArray(0)), 0, HashAlgorithm.SHA1, 6) }
        fails { hotp(Secret(seed20), -1, HashAlgorithm.SHA1, 6) }
        fails { hotp(Secret(seed20), 0, HashAlgorithm.SHA1, 7) }
    }

    @Test
    fun totpRfc6238() {
        assertEquals("94287082", totp(Secret(seed20), 59, HashAlgorithm.SHA1, 8, 30))
        assertEquals("68084774", totp(Secret(seed32), 1_111_111_109, HashAlgorithm.SHA256, 8, 30))
        assertEquals("99943326", totp(Secret(seed64), 1_111_111_111, HashAlgorithm.SHA512, 8, 30))
    }

    @Test
    fun totpDefaultsToThirtySeconds() {
        val secret = Secret(seed20)
        assertEquals(totp(secret, 59, HashAlgorithm.SHA1, 8, 30), totp(secret, 59, HashAlgorithm.SHA1, 8))
    }

    @Test
    fun totpRejectsNonPositivePeriod() {
        fails { totp(Secret(seed20), 59, HashAlgorithm.SHA1, 8, 0) }
        fails { totp(Secret(seed20), 59, HashAlgorithm.SHA1, 8, -30) }
    }
}

internal fun fails(block: () -> Unit) {
    try {
        block()
    } catch (_: OtpException) {
        return
    }
    error("expected OtpException")
}
