plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Stable release signing: every release must be signed with the SAME key, or
// phones with an older install reject the update
// (INSTALL_FAILED_UPDATE_INCOMPATIBLE, getPackageInfo -> null).
// CI injects the keystore from GitHub Secrets via env vars
// (KEYSTORE_PATH / KEY_ALIAS / KEY_STORE_PASSWORD / KEY_PASSWORD);
// locally it falls back to debug signing for `flutter run --release`.
val ksPath = System.getenv("KEYSTORE_PATH")?.takeIf { it.isNotEmpty() }
val ksAlias = System.getenv("KEY_ALIAS")?.takeIf { it.isNotEmpty() }
val ksStorePassword = System.getenv("KEY_STORE_PASSWORD")?.takeIf { it.isNotEmpty() }
val ksKeyPassword = System.getenv("KEY_PASSWORD")?.takeIf { it.isNotEmpty() }
val hasReleaseSigning = ksPath != null && ksAlias != null &&
    ksStorePassword != null && ksKeyPassword != null
val isCi = System.getenv("CI") == "true" || System.getenv("GITHUB_ACTIONS") == "true"
if (isCi && !hasReleaseSigning) {
    val missingSigningVars = listOf(
        "KEYSTORE_PATH" to ksPath,
        "KEY_ALIAS" to ksAlias,
        "KEY_STORE_PASSWORD" to ksStorePassword,
        "KEY_PASSWORD" to ksKeyPassword,
    ).filter { it.second == null }.map { it.first }
    error("CI release build without complete release-signing env vars. " +
        "Missing: ${missingSigningVars.joinToString(", ")}. " +
        "Add them as GitHub Secrets — see .github/workflows/build-release.yml. " +
        "If a stale debug-signed install blocks the update " +
        "(INSTALL_FAILED_UPDATE_INCOMPATIBLE), uninstall it first: " +
        "adb uninstall com.github.kfatyuip.ayatsuri")
}

android {
    namespace = "com.github.kfatyuip.ayatsuri"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.github.kfatyuip.ayatsuri"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (ksPath != null) {
                storeFile = file(ksPath)
            }
            storePassword = ksStorePassword ?: ""
            keyAlias = ksAlias ?: ""
            keyPassword = ksKeyPassword ?: ""
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                // Local only: isCi builds already failed above.
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
