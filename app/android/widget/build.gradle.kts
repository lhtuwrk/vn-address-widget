plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    namespace = "com.vnaddress.widget.glance"
    compileSdk = 34
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        minSdk = 26
        // ADR 0002 §9: same ABI restriction as :app, so the two never
        // disagree about which native library variants exist.
        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
    }
}

dependencies {
    implementation("androidx.glance:glance-appwidget:1.1.0")
    implementation("androidx.core:core-ktx:1.13.1")
}
