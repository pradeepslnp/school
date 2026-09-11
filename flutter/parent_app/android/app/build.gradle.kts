import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// P-04 Live Trip Map's Maps API key (AndroidManifest.xml). Never committed: an environment
// variable takes priority (CI, or a developer's shell profile), falling back to
// local.properties — already gitignored for the Flutter SDK path, so it is the natural place
// to add one more machine-local, non-secret-in-the-Anthropic-sense-but-still-not-public value
// (docs/06-development/LOCAL_SETUP.md, CLAUDE.md §7). Empty when neither is set, which is a
// valid build: the map just renders no tiles.
val localProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { load(it) }
    }
}
val mapsApiKey: String =
    (System.getenv("MAPS_API_KEY") ?: localProperties.getProperty("MAPS_API_KEY") ?: "")

android {
    namespace = "com.guardian.guardian_parent"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.guardian.guardian_parent"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Guardian Parent (DEV)")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Guardian Parent")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
