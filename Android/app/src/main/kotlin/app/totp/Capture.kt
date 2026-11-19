package app.totp

import android.graphics.Bitmap
import android.net.Uri
import app.totp.core.ffi.CoreException
import app.totp.core.ffi.ParsedAccount
import app.totp.core.ffi.parseOtpauthUri
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

sealed interface CaptureResult {
    data class Saved(val account: ParsedAccount) : CaptureResult
    data class Rejected(val reason: String) : CaptureResult
}

fun acceptPayloads(payloads: List<String>): CaptureResult {
    val accepted = payloads.mapNotNull { payload ->
        try {
            parseOtpauthUri(payload)
        } catch (_: CoreException) {
            null
        }
    }
    return if (accepted.size == 1) CaptureResult.Saved(accepted.single())
    else CaptureResult.Rejected(if (payloads.isEmpty()) "没有识别到二维码" else "没有唯一的 otpauth 账户")
}

class BarcodeReader {
    private val scanner = BarcodeScanning.getClient()

    suspend fun read(image: InputImage): List<String> =
        scanner.process(image).awaitResult().mapNotNull { it.rawValue }

    suspend fun read(bitmap: Bitmap) = read(InputImage.fromBitmap(bitmap, 0))

    suspend fun read(context: android.content.Context, uri: Uri) =
        read(InputImage.fromFilePath(context, uri))
}

private suspend fun <T> com.google.android.gms.tasks.Task<T>.awaitResult(): T =
    suspendCancellableCoroutine { continuation ->
        addOnSuccessListener { continuation.resume(it) }
        addOnFailureListener { continuation.resumeWithException(it) }
    }
