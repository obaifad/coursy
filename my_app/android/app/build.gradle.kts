import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// مفتاح توقيع الإصدار من android/key.properties (خارج git). بدونه يُوقَّع بمفتاح debug للتجربة فقط.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "sy.coursy.app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // المعرّف النهائي على Google Play — لا يمكن تغييره بعد النشر.
        applicationId = "sy.coursy.app"
        minSdk = 23
        // Google Play يشترط Android 16 (API 36) للتطبيقات الجديدة والتحديثات منذ 31 أغسطس 2026.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
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
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // APK تجريبي فقط — حزمة Google Play (AAB) ترفض البناء بدون مفتاح الرفع (انظر أدناه).
                signingConfigs.getByName("debug")
            }
        }
    }
}

// Google Play يرفض الحزم الموقّعة بمفتاح debug: لا نبني AAB للإصدار بدون key.properties.
gradle.taskGraph.whenReady {
    val buildsReleaseBundle = allTasks.any { it.project == project && it.name.startsWith("bundle") && it.name.endsWith("Release") }
    if (buildsReleaseBundle && !keystorePropertiesFile.exists()) {
        throw GradleException(
            "android/key.properties غير موجود: حزمة Google Play يجب أن توقَّع بمفتاح الرفع " +
                "(scripts/create_release_keystore.ps1). / android/key.properties is missing: " +
                "a Google Play bundle must be signed with the upload key.",
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}
