plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
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

    buildTypes {
        release {
            // Stable release signing: every tagged release must be signed with
            // the SAME key, or phones with an older install reject the update
            // (INSTALL_FAILED_UPDATE_INCOMPATIBLE, getPackageInfo -> null).
            // CI injects the keystore from GitHub Secrets via env vars
            // (KEYSTORE_PATH / KEY_ALIAS / KEY_STORE_PASSWORD / KEY_PASSWORD);
            // locally it falls back to debug signing for `flutter run --release`.
            val ksPath = System.getenv("KEYSTORE_PATH")?.takeIf { it.isNotEmpty() }
            val ksAlias = System.getenv("KEY_ALIAS")?.takeIf { it.isNotEmpty() }
            val ksStorePassword = System.getenv("KEY_STORE_PASSWORD")?.takeIf { it.isNotEmpty() }
            val ksKeyPassword = System.getenv("KEY_PASSWORD")?.takeIf { it.isNotEmpty() }
            signingConfig = if (ksPath != null && ksAlias != null &&
                ksStorePassword != null && ksKeyPassword != null
            ) {
                signingConfigs.create("release") {
                    storeFile = file(ksPath)
                    storePassword = ksStorePassword
                    keyAlias = ksAlias
                    keyPassword = ksKeyPassword
                }
            } else {
                if (System.getenv("CI") == "true" && System.getenv("GITHUB_REF")?.startsWith("refs/tags/v") == true) {
                    error("Release build on a v* tag without release-signing env vars " +
                        "(KEYSTORE_PATH/KEY_ALIAS/KEY_STORE_PASSWORD/KEY_PASSWORD). " +
                        "Add them as GitHub Secrets — see .github/workflows/build-release.yml.")
                }
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
