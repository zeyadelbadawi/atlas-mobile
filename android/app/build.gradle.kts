import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing comes from android/key.properties (a local, git-ignored
// file) or, in CI, from ATLAS_UPLOAD_* environment variables. When neither
// is present the release build falls back to the debug key, so
// `flutter run --release` and plain CI builds keep working without the
// upload key. The keystore and its passwords are never committed.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun signingValue(propKey: String, envKey: String): String? =
    keystoreProperties.getProperty(propKey) ?: System.getenv(envKey)

val uploadStoreFile = signingValue("storeFile", "ATLAS_UPLOAD_STORE_FILE")

android {
    namespace = "com.atlas.atlas_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications (study and due-date reminders).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.atlas.atlas_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        // Google Play: new apps and updates must target Android 16 (API 36)
        // from 31 August 2026.
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (uploadStoreFile != null) {
                storeFile = file(uploadStoreFile)
                storePassword = signingValue("storePassword", "ATLAS_UPLOAD_STORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "ATLAS_UPLOAD_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "ATLAS_UPLOAD_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // The upload key when it is configured; otherwise the debug key,
            // so a build without the key still works (it just isn't publishable).
            signingConfig = if (uploadStoreFile != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
