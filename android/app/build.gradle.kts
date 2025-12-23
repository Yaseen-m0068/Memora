plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")      // use the modern kotlin plugin id
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.memora"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.memora"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 1                      // Kotlin DSL uses =
        versionName = "1.0.0"
    }

    // Java/Kotlin toolchains (match Flutter template)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        getByName("debug") {
            // debug defaults
        }
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            // For demo builds you can use debug signing; for store builds set a release keystore:
            // signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
