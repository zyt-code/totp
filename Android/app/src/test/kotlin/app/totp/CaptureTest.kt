package app.totp

import org.junit.Assert.assertEquals
import org.junit.Test

class CaptureTest {
    // 其余用例要走 JNA 加载 arm64-v8a 的 .so，只在仪器测试里跑（见 CoreBindingTest）。
    @Test
    fun noPayloadRejects() {
        assertEquals("没有识别到二维码", (acceptPayloads(emptyList()) as CaptureResult.Rejected).reason)
    }
}
