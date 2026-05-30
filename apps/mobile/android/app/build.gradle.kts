import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ynot.ynot_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    val envFile = rootProject.projectDir.parentFile.resolve(".env")
    val envExampleFile = rootProject.projectDir.parentFile.resolve(".env.example")

    fun loadDotEnv(file: File): Map<String, String> {
        if (!file.exists()) {
            return emptyMap()
        }

        return file.readLines()
            .mapNotNull { rawLine ->
                val line = rawLine.trim()
                if (line.isBlank() || line.startsWith("#") || !line.contains("=")) {
                    return@mapNotNull null
                }

                val parts = line.split("=", limit = 2)
                if (parts.size != 2) {
                    return@mapNotNull null
                }

                val key = parts[0].trim()
                val value = parts[1].trim().trim('"').trim('\'')
                if (key.isEmpty()) {
                    return@mapNotNull null
                }

                key to value
            }
            .toMap()
    }

    val env = loadDotEnv(if (envFile.exists()) envFile else envExampleFile)
    val googleMapsApiKey = env["GOOGLE_MAPS_API_KEY"].orEmpty()

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ynot.ynot_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
