package app.totp

import androidx.room.Room
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import app.totp.core.HashAlgorithm
import app.totp.core.OtpauthFields
import app.totp.core.decodeBase32
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

    @Test
    fun secretRoundTripsEncrypted() = runBlocking {
        store.add(OtpauthFields("GitHub ada", "GEZDGNBV", HashAlgorithm.SHA1, 6, 30))
        val loaded = store.accounts().single()
        assertEquals("GitHub", loaded.siteName)
        assertEquals("ada", loaded.username)
        assertEquals(decodeBase32("GEZDGNBV").toList(), loaded.secret.toList())

        val onDisk = database.accounts().secret(loaded.id)!!.ciphertext
        assertFalse(onDisk.contentEquals(decodeBase32("GEZDGNBV")))
    }

    @Test
    fun missingSecretIsSkipped() = runBlocking {
        store.add(OtpauthFields("GitHub", "GEZDGNBV", HashAlgorithm.SHA1, 6, 30))
        val id = store.accounts().single().id
        database.accounts().deleteSecret(id)
        assertEquals(emptyList<StoredAccount>(), store.accounts())
    }

    @Test
    fun deleteRemovesMetadataAndSecret() = runBlocking {
        store.add(OtpauthFields("GitHub", "GEZDGNBV", HashAlgorithm.SHA1, 6, 30))
        val id = store.accounts().single().id
        store.delete(id)
        assertNull(database.accounts().byId(id))
        assertNull(database.accounts().secret(id))
    }

    @Test
    fun renameSplitsAndRejectsBlank() = runBlocking {
        store.add(OtpauthFields("GitHub ada", "GEZDGNBV", HashAlgorithm.SHA1, 6, 30))
        val id = store.accounts().single().id
        assertEquals(true, store.rename(id, "GitLab ada"))
        assertEquals("GitLab ada", store.accounts().single().displayName)
        assertEquals(false, store.rename(id, "   "))
        assertEquals("GitLab ada", store.accounts().single().displayName)
    }

    @Test
    fun listingKeepsInsertionOrder() = runBlocking {
        store.add(OtpauthFields("First", "GEZDGNBV", HashAlgorithm.SHA1, 6, 30))
        store.add(OtpauthFields("Second", "GEZDGNBV", HashAlgorithm.SHA1, 6, 30))
        assertEquals(listOf("First", "Second"), store.accounts().map { it.siteName })
    }
}
