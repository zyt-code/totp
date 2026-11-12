package app.totp

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class SchemaTest {
    private val schema: String by lazy {
        File("schemas/app.totp.AccountDatabase/1.json").readText()
    }

    @Test
    fun metadataTableHasNoSecretColumn() {
        val accounts = table("accounts")
        assertFalse(accounts.contains("\"columnName\": \"secret\""))
        listOf("id", "siteName", "username", "algorithm", "digits", "period", "position").forEach {
            assertTrue("missing column $it", accounts.contains("\"columnName\": \"$it\""))
        }
    }

    @Test
    fun ciphertextLivesInItsOwnTable() {
        assertTrue(table("secrets").contains("\"columnName\": \"ciphertext\""))
    }

    @Test
    fun schemaVersionIsOne() {
        assertEquals(1, Regex("\"version\": (\\d+)").find(schema)!!.groupValues[1].toInt())
    }

    private fun table(name: String): String {
        val start = schema.indexOf("\"tableName\": \"$name\"")
        check(start >= 0) { "table $name not in schema" }
        return schema.substring(start, schema.indexOf("]", start))
    }
}
