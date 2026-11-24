import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.hopetv.iptvplayer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    val isTvBuild = project.hasProperty("tvBuild") || project.findProperty("appSuffix") == "tv"
    val isTvOptimized = isTvBuild || project.hasProperty("tvOptimize")
    val isSplitPerAbi = project.findProperty("split-per-abi")?.toString()?.toBoolean() == true
    val appIdSuffix = if (isTvBuild) ".tv" else ""
    val requestedAbis = (project.findProperty("targetAbis") as String?)
        ?.split(",")
        ?.map { it.trim() }
        ?.filter { it.isNotEmpty() }

    defaultConfig {
        applicationId = "com.hopetv.iptvplayer$appIdSuffix"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = if (isTvBuild) "HOPE TV" else "HOPE IPTV"

        if (!isSplitPerAbi) {
            ndk {
                if (!requestedAbis.isNullOrEmpty()) {
                    abiFilters.addAll(requestedAbis)
                } else {
                    // Exclude dead x86/x86_64 native libraries (~76 MB) from universal APKs.
                    abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
                }
            }
        }
    }

    packaging {
        jniLibs {
            // Deflate-compress native .so libraries (libvlc, libmpv, libflutter, libapp)
            // inside the APK instead of storing them raw/uncompressed (~55-60% smaller APK).
            useLegacyPackaging = true
            excludes += setOf(
                "**/x86/**",
                "**/x86_64/**",
            )
            if (isTvOptimized) {
                // Android TV displays a QR code for companion sign-in and never uses
                // a rear camera to scan barcodes; exclude ML Kit barcode camera libs.
                excludes += setOf(
                    "**/libbarhopper_v3.so",
                    "**/libimage_processing_util_jni.so",
                    "**/libsurface_util_jni.so",
                )
            }
        }
        resources {
            excludes += setOf(
                "DebugProbesKt.bin",
                "kotlin-tooling-metadata.json",
                "META-INF/*.version",
                "META-INF/proguard/**",
            )
            if (isTvOptimized) {
                excludes += setOf(
                    "assets/mlkit_barcode_models/**",
                )
            }
        }
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Produce an unsigned artifact locally instead of silently
                // shipping a release that is signed with the debug key.
                null
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Keep the selectable Android backends on reviewed upstream releases.
// Gradle resolves these over the older transitive plugin versions.
dependencies {
    val media3Version = "1.11.1"
    implementation("androidx.media3:media3-exoplayer:$media3Version")
    implementation("androidx.media3:media3-exoplayer-hls:$media3Version")
    implementation("androidx.media3:media3-exoplayer-dash:$media3Version")
    implementation("androidx.media3:media3-exoplayer-rtsp:$media3Version")
    implementation("androidx.media3:media3-exoplayer-smoothstreaming:$media3Version")
    implementation("org.videolan.android:libvlc-all:3.7.6")
}
