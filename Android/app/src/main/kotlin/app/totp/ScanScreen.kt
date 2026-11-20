package app.totp

import androidx.activity.compose.BackHandler
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.FlashlightOff
import androidx.compose.material.icons.filled.FlashlightOn
import androidx.compose.material.icons.outlined.PhotoLibrary
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage

@androidx.annotation.OptIn(ExperimentalGetImage::class)
@Composable
fun ScanScreen(
    message: String? = null,
    consumeMessage: () -> Unit = {},
    onResult: (CaptureResult) -> Unit,
    onPickImage: () -> Unit,
    onBack: () -> Unit,
) {
    BackHandler(onBack = onBack)
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val scanner = remember { BarcodeScanning.getClient() }
    DisposableEffect(Unit) { onDispose { scanner.close() } }

    val snackbarHostState = remember { SnackbarHostState() }
    var pendingMessage by remember { mutableStateOf<String?>(null) }
    LaunchedEffect(message) {
        if (message != null) {
            pendingMessage = message
            consumeMessage()
        }
    }
    LaunchedEffect(pendingMessage) {
        val current = pendingMessage ?: return@LaunchedEffect
        snackbarHostState.showSnackbar(current)
        if (pendingMessage == current) {
            pendingMessage = null
        }
    }

    var isProcessing by remember { mutableStateOf(false) }
    var camera by remember { mutableStateOf<Camera?>(null) }
    var provider by remember { mutableStateOf<ProcessCameraProvider?>(null) }
    var torchOn by remember { mutableStateOf(false) }
    var torchAvailable by remember { mutableStateOf(false) }
    LaunchedEffect(torchOn, camera) { camera?.cameraControl?.enableTorch(torchOn) }
    DisposableEffect(Unit) { onDispose { provider?.unbindAll() } }

    Box(Modifier.fillMaxSize().background(Color.Black)) {
        AndroidView(
            factory = { context ->
                PreviewView(context).apply { scaleType = PreviewView.ScaleType.FILL_CENTER }.also { previewView ->
                    // 只在视图创建时绑定一次，重组（例如切换手电筒）不会重开相机。
                    val future = ProcessCameraProvider.getInstance(previewView.context)
                    future.addListener({
                        val bound = future.get().also { provider = it }
                        val preview = Preview.Builder().build().also { it.surfaceProvider = previewView.surfaceProvider }
                        val analysis = ImageAnalysis.Builder().build().also { useCase ->
                            useCase.setAnalyzer(ContextCompat.getMainExecutor(previewView.context)) { image ->
                                val media = image.image
                                if (media == null) {
                                    image.close()
                                } else {
                                    scanner.process(InputImage.fromMediaImage(media, image.imageInfo.rotationDegrees))
                                        .addOnSuccessListener { codes ->
                                            if (isProcessing) return@addOnSuccessListener
                                            val payloads = codes.mapNotNull { it.rawValue }
                                            // 无码帧保持安静，只有识别到内容才反馈。
                                            if (payloads.isNotEmpty()) {
                                                val result = acceptPayloads(payloads)
                                                if (result is CaptureResult.Saved) {
                                                    isProcessing = true
                                                }
                                                onResult(result)
                                            }
                                        }
                                        .addOnCompleteListener { image.close() }
                                }
                            }
                        }
                        bound.unbindAll()
                        val active = bound.bindToLifecycle(
                            lifecycleOwner,
                            CameraSelector.DEFAULT_BACK_CAMERA,
                            preview,
                            analysis,
                        )
                        camera = active
                        torchAvailable = active.cameraInfo.hasFlashUnit()
                    }, ContextCompat.getMainExecutor(previewView.context))
                }
            },
            modifier = Modifier.fillMaxSize(),
        )

        ScanOverlay()

        Surface(
            onClick = onBack,
            shape = CircleShape,
            color = Color.Black.copy(alpha = 0.35f),
            contentColor = Color.White,
            modifier = Modifier.align(Alignment.TopStart).statusBarsPadding().padding(start = 16.dp, top = 8.dp).size(40.dp),
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回", tint = Color.White)
            }
        }

        SnackbarHost(
            hostState = snackbarHostState,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .navigationBarsPadding()
                .padding(bottom = 124.dp),
        )

        Text(
            "将二维码放入框内",
            color = Color.White.copy(alpha = 0.9f),
            modifier = Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(bottom = 92.dp),
        )

        Row(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .navigationBarsPadding()
                .padding(bottom = 28.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            ToolbarButton(
                onClick = { torchOn = !torchOn },
                label = if (torchOn) "关闭手电筒" else "手电筒",
                enabled = torchAvailable,
            ) {
                Icon(
                    if (torchOn) Icons.Filled.FlashlightOff else Icons.Filled.FlashlightOn,
                    contentDescription = if (torchOn) "关闭手电筒" else "手电筒",
                    tint = if (torchAvailable) Color.White else Color.White.copy(alpha = 0.4f),
                )
            }
            ToolbarButton(onClick = onPickImage, label = "相册选图", enabled = true) {
                Icon(Icons.Outlined.PhotoLibrary, contentDescription = "从相册选择二维码", tint = Color.White)
            }
        }
    }
}

@Composable
private fun ToolbarButton(
    onClick: () -> Unit,
    label: String,
    enabled: Boolean,
    content: @Composable () -> Unit,
) {
    Surface(
        onClick = onClick,
        enabled = enabled,
        shape = CircleShape,
        color = Color.Black.copy(alpha = 0.42f),
        contentColor = Color.White,
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 18.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            content()
            Text(label, color = if (enabled) Color.White else Color.White.copy(alpha = 0.4f))
        }
    }
}

/** 暗色遮罩 + 中央圆角镂空 + 四角指示线。 */
@Composable
private fun ScanOverlay() {
    Canvas(Modifier.fillMaxSize()) {
        val frameSize = size.minDimension * 0.68f
        val left = (size.width - frameSize) / 2f
        val top = (size.height - frameSize) / 2f - 40.dp.toPx()
        val radius = 24.dp.toPx()
        val frame = Rect(left, top, left + frameSize, top + frameSize)

        // 奇偶填充：整屏减去圆角方框，得到真正的圆角镂空。
        val scrim = Path().apply {
            fillType = PathFillType.EvenOdd
            addRect(Rect(0f, 0f, size.width, size.height))
            addRoundRect(RoundRect(frame, CornerRadius(radius)))
        }
        drawPath(scrim, Color.Black.copy(alpha = 0.6f))

        val line = 3.dp.toPx()
        val arm = 26.dp.toPx()
        val white = Color.White
        listOf(
            // 左上
            Offset(frame.left, frame.top) to Offset(frame.left + arm, frame.top),
            Offset(frame.left, frame.top) to Offset(frame.left, frame.top + arm),
            // 右上
            Offset(frame.right, frame.top) to Offset(frame.right - arm, frame.top),
            Offset(frame.right, frame.top) to Offset(frame.right, frame.top + arm),
            // 左下
            Offset(frame.left, frame.bottom) to Offset(frame.left + arm, frame.bottom),
            Offset(frame.left, frame.bottom) to Offset(frame.left, frame.bottom - arm),
            // 右下
            Offset(frame.right, frame.bottom) to Offset(frame.right - arm, frame.bottom),
            Offset(frame.right, frame.bottom) to Offset(frame.right, frame.bottom - arm),
        ).forEach { (start, end) ->
            drawLine(white, start, end, strokeWidth = line, cap = StrokeCap.Round)
        }
        drawRoundRect(
            color = white.copy(alpha = 0.25f),
            topLeft = Offset(frame.left, frame.top),
            size = Size(frame.width, frame.height),
            cornerRadius = CornerRadius(radius),
            style = Stroke(1.dp.toPx()),
        )
    }
}
