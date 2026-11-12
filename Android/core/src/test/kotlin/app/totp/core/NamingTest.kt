package app.totp.core

import org.junit.Assert.assertEquals
import org.junit.Test

class NamingTest {
    @Test
    fun splitsAtFirstSpace() {
        assertEquals("GitHub" to "ada", splitName("GitHub ada"))
    }

    @Test
    fun keepsRestInUsername() {
        assertEquals("Work" to "ada lovelace", splitName("Work ada lovelace"))
    }

    @Test
    fun noSpaceMeansNoUsername() {
        assertEquals("GitHub" to "", splitName("GitHub"))
    }

    @Test
    fun trimsSurroundingSpace() {
        assertEquals("GitHub" to "ada", splitName("  GitHub ada  "))
    }

    @Test
    fun colonSplitsIssuerFromAccount() {
        assertEquals("OpenAI" to "me@x.com", splitName("OpenAI:me@x.com"))
    }

    @Test
    fun repeatedAccountIsCollapsed() {
        assertEquals("OpenAI" to "me@x.com", splitName("OpenAI:me@x.com me@x.com"))
    }

    @Test
    fun labelsHideDuplicatedAccount() {
        assertEquals("OpenAI" to "me@x.com", accountLabels("OpenAI:me@x.com", "me@x.com"))
    }

    @Test
    fun labelsKeepSeparateUsername() {
        assertEquals("GitHub" to "ada", accountLabels("GitHub", "ada"))
    }

    @Test
    fun labelsFallBackToImpliedAccount() {
        assertEquals("OpenAI" to "me@x.com", accountLabels("OpenAI:me@x.com", ""))
    }
}
