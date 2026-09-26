plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.vnaddress.widget"
    compileSdk = 34
    ndkVersion = "27.0.12077973" // ADR 0002 §9: NDK r28+ preferred once available, for 16KB page alignment by default.

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.vnaddress.widget"
        // ADR 0002 §6: proposed default floor, pending org confirmation.
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "0.1.0"

        ndk {
            // ADR 0002 §9: explicit ABI restriction — a 32-bit-only device is
            // refused at install time rather than crashing on first launch
            // when libvnaddr.so isn't found for its ABI.
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ADR 0002 §1a: :widget is a library module depended on by :app, so both
    // ship in the same APK / same process (ADR 0002 §4).
    implementation(project(":widget"))
}
