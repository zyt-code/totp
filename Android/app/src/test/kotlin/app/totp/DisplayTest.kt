package app.totp

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DisplayTest {
    @Test
    fun groupsSixDigits() {
        assertEquals("404 162", formatCode("404162", grouped = true))
        assertEquals("404162", formatCode("404162", grouped = false))
    }

    @Test
    fun leavesEightDigitsContiguous() {
        assertEquals("40416270", formatCode("40416270", grouped = true))
    }

    @Test
    fun warningAtFiveSeconds() {
        assertTrue(expiring(5))
        assertFalse(expiring(6))
    }

    @Test
    fun clearOnlyWhenClipboardUnchanged() {
        assertTrue(shouldClear("404162", "404162"))
        assertFalse(shouldClear("404162", "other"))
        assertFalse(shouldClear("404162", null))
    }
}
