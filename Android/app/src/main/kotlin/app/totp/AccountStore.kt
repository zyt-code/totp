package app.totp

import android.content.Context
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.Room
import androidx.room.RoomDatabase
import app.totp.core.Account
import app.totp.core.HashAlgorithm
import app.totp.core.OtpauthFields
import app.totp.core.decodeBase32
import app.totp.core.accountLabels
import app.totp.core.splitName
import com.google.crypto.tink.Aead
import com.google.crypto.tink.KeyTemplates
import com.google.crypto.tink.RegistryConfiguration
import com.google.crypto.tink.aead.AeadConfig
import com.google.crypto.tink.integration.android.AndroidKeysetManager
import java.util.UUID

/** 账户元数据。密钥不在这一张表里。 */
@Entity(tableName = "accounts")
data class AccountRow(
    @PrimaryKey val id: String,
    val siteName: String,
    val username: String,
    val algorithm: String,
    val digits: Int,
    val period: Int,
    val position: Long,
)

/** 每个账户 id 对应的加密密钥。 */
@Entity(tableName = "secrets")
data class SecretRow(
    @PrimaryKey val id: String,
    val ciphertext: ByteArray,
)

@Dao
interface AccountDao {
    @Query("SELECT * FROM accounts ORDER BY position")
    suspend fun all(): List<AccountRow>

    @Query("SELECT * FROM accounts WHERE id = :id")
    suspend fun byId(id: String): AccountRow?

    @Query("SELECT * FROM secrets")
    suspend fun secrets(): List<SecretRow>

    @Query("SELECT * FROM secrets WHERE id = :id")
    suspend fun secret(id: String): SecretRow?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun save(row: AccountRow)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun saveSecret(row: SecretRow)

    @Query("DELETE FROM accounts WHERE id = :id")
    suspend fun delete(id: String)

    @Query("DELETE FROM secrets WHERE id = :id")
    suspend fun deleteSecret(id: String)

    @Query("SELECT COALESCE(MAX(position), 0) FROM accounts")
    suspend fun maxPosition(): Long
}

@Database(entities = [AccountRow::class, SecretRow::class], version = 1, exportSchema = true)
abstract class AccountDatabase : RoomDatabase() {
    abstract fun accounts(): AccountDao
}

class AccountStore(context: Context, private val database: AccountDatabase) {
    private val aead: Aead

    init {
        AeadConfig.register()
        val handle = AndroidKeysetManager.Builder()
            .withSharedPref(context, "totp_keyset", "totp_keyset_prefs")
            .withKeyTemplate(KeyTemplates.get("AES256_GCM"))
            .withMasterKeyUri("android-keystore://totp_master_key")
            .build()
            .keysetHandle
        aead = handle.getPrimitive(RegistryConfiguration.get(), Aead::class.java)
    }

    suspend fun accounts(): List<StoredAccount> {
        val secrets = database.accounts().secrets().associateBy { it.id }
        return database.accounts().all().mapNotNull { row ->
            val ciphertext = secrets[row.id]?.ciphertext ?: return@mapNotNull null
            val bytes = try {
                aead.decrypt(ciphertext, row.id.toByteArray())
            } catch (_: Exception) {
                return@mapNotNull null
            }
            StoredAccount(row.id, row.siteName, row.username, bytes, HashAlgorithm.valueOf(row.algorithm), row.digits, row.period)
        }
    }

    suspend fun add(fields: OtpauthFields) {
        val (siteName, username) = splitName(fields.name)
        save(UUID.randomUUID().toString(), siteName, username, decodeBase32(fields.secret), fields.algorithm, fields.digits, fields.period)
    }

    suspend fun rename(id: String, name: String): Boolean {
        if (name.isBlank()) return false
        val current = database.accounts().byId(id) ?: return false
        val (siteName, username) = splitName(name)
        database.accounts().save(current.copy(siteName = siteName, username = username))
        return true
    }

    suspend fun delete(id: String) {
        database.accounts().delete(id)
        database.accounts().deleteSecret(id)
    }

    private suspend fun save(
        id: String,
        siteName: String,
        username: String,
        secret: ByteArray,
        algorithm: HashAlgorithm,
        digits: Int,
        period: Int,
    ) {
        val position = database.accounts().maxPosition() + 1
        database.accounts().save(AccountRow(id, siteName, username, algorithm.name, digits, period, position))
        database.accounts().saveSecret(SecretRow(id, aead.encrypt(secret, id.toByteArray())))
    }

    companion object {
        fun create(context: Context) = AccountStore(
            context.applicationContext,
            Room.databaseBuilder(context.applicationContext, AccountDatabase::class.java, "accounts.db").build(),
        )
    }
}

data class StoredAccount(
    val id: String,
    val siteName: String,
    val username: String,
    val secret: ByteArray,
    val algorithm: HashAlgorithm,
    val digits: Int,
    val period: Int,
) {
    fun toAccount() = Account(siteName, username, secret, algorithm, digits, period)
    /** 兼容历史数据：站点里带 "Issuer:Account" 且账号列重复时，标题只留 Issuer。 */
    val labels: Pair<String, String> get() = accountLabels(siteName, username)
    val displayName: String get() = labels.toList().filter { it.isNotEmpty() }.joinToString(" ")
}
