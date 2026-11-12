package app.totp

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class CaptureTest {
    @Test
    fun oneValidUriSaves() {
        val result = acceptPayloads(listOf("otpauth://totp/GitHub:ada?secret=GEZDGNBV"))
        assertTrue(result is CaptureResult.Saved)
    }

    @Test
    fun invalidPayloadRejects() {
        val result = acceptPayloads(listOf("https://example.com"))
        assertTrue(result is CaptureResult.Rejected)
    }

    @Test
    fun noPayloadRejects() {
        assertEquals("没有识别到二维码", (acceptPayloads(emptyList()) as CaptureResult.Rejected).reason)
    }
}
