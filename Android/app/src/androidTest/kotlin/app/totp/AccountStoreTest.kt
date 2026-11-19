package app.totp

import androidx.room.Room
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import app.totp.core.ffi.HashAlgorithm
import app.totp.core.ffi.ParsedAccount
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class AccountStoreTest {
    private val context = InstrumentationRegistry.getInstrumentation().targetContext
    private val database = Room.inMemoryDatabaseBuilder(context, AccountDatabase::class.java).build()
    private val store = AccountStore(context, database)

    @After
    fun close() = database.close()

    private fun parsed(issuer: String = "GitHub", accountName: String = "ada") = ParsedAccount(
        issuer = issuer,
        accountName = accountName,
        secret = "12345678901234567890".toByteArray(),
        algorithm = HashAlgorithm.SHA1,
        digits = 6,
        period = 30,
    )

    @Test
    fun secretRoundTripsEncrypted() = runBlocking {
        store.add(parsed())
        val loaded = store.accounts().single()
        assertEquals("GitHub", loaded.siteName)
        assertEquals("ada", loaded.username)
        assertEquals("12345678901234567890", String(loaded.secret))

        val onDisk = database.accounts().secret(loaded.id)!!.ciphertext
        assertFalse(onDisk.contentEquals("12345678901234567890".toByteArray()))
    }

    @Test
    fun parsedLabelWithoutIssuerIsSplit() = runBlocking {
        store.add(parsed(issuer = "", accountName = "GitHub ada"))
        val loaded = store.accounts().single()
        assertEquals("GitHub", loaded.siteName)
        assertEquals("ada", loaded.username)
    }

    @Test
    fun missingSecretIsSkipped() = runBlocking {
        store.add(parsed())
        val id = store.accounts().single().id
        database.accounts().deleteSecret(id)
        assertEquals(emptyList<StoredAccount>(), store.accounts())
    }

    @Test
    fun deleteRemovesMetadataAndSecret() = runBlocking {
        store.add(parsed())
        val id = store.accounts().single().id
        store.delete(id)
        assertNull(database.accounts().byId(id))
        assertNull(database.accounts().secret(id))
    }

    @Test
    fun renameSplitsAndRejectsBlank() = runBlocking {
        store.add(parsed())
        val id = store.accounts().single().id
        assertEquals(true, store.rename(id, "GitLab ada"))
        assertEquals("GitLab ada", store.accounts().single().displayName)
        assertEquals(false, store.rename(id, "   "))
        assertEquals("GitLab ada", store.accounts().single().displayName)
    }

    @Test
    fun listingKeepsInsertionOrder() = runBlocking {
        store.add(parsed(issuer = "First", accountName = ""))
        store.add(parsed(issuer = "Second", accountName = ""))
        assertEquals(listOf("First", "Second"), store.accounts().map { it.siteName })
    }
}
