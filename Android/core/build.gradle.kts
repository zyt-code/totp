plugins {
    id("com.android.library")
}

android {
    namespace = "app.totp.core"
    compileSdk = 37

    defaultConfig {
        minSdk = 26
    }
}

kotlin {
    jvmToolchain(21)
}

dependencies {
    // UniFFI 生成的绑定用 JNA 调 libtotp_core.so；aar 按 ABI 带 libjnidispatch.so。
    implementation("net.java.dev.jna:jna:5.17.0@aar")
}
