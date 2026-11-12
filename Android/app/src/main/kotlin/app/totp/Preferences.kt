package app.totp

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore by preferencesDataStore("settings")

class Preferences(private val context: Context) {
    private val autoClear = booleanPreferencesKey("auto_clear")
    private val grouped = booleanPreferencesKey("grouped")
    private val allowScreenshots = booleanPreferencesKey("allow_screenshots")

    val values: Flow<Settings> = context.dataStore.data.map { prefs ->
        Settings(
            autoClear = prefs[autoClear] ?: true,
            grouped = prefs[grouped] ?: true,
            allowScreenshots = prefs[allowScreenshots] ?: false,
        )
    }

    suspend fun setAutoClear(enabled: Boolean) {
        context.dataStore.edit { it[autoClear] = enabled }
    }

    suspend fun setGrouped(enabled: Boolean) {
        context.dataStore.edit { it[grouped] = enabled }
    }

    suspend fun setAllowScreenshots(enabled: Boolean) {
        context.dataStore.edit { it[allowScreenshots] = enabled }
    }
}

data class Settings(
    val autoClear: Boolean,
    val grouped: Boolean,
    val allowScreenshots: Boolean = false,
)
