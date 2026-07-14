import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma de release opcional: si existe android/key.properties se usa el keystore
// real (necesario para publicar en Play Store); si no, se cae a la firma de
// debug para que `flutter run --release` siga funcionando en desarrollo.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.example.minex"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: identificador único propio antes de publicar (no puede empezar por
        // "com.example"): p. ej. "com.tuestudio.minex".
        applicationId = "com.example.minex"
        // minSdk 24 (Android 7.0) cubre ~99% de dispositivos activos y es el
        // mínimo que exige google_mobile_ads 9. Se toma el mayor entre 24 y el
        // que recomienda Flutter para no bajar por debajo del engine.
        minSdk = maxOf(24, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Multidex por seguridad con muchas dependencias (nativo en minSdk 21+).
        multiDexEnabled = true
    }

    // Empaqueta las librerías nativas SIN comprimir: requisito para que el
    // cargador pueda mapearlas en memoria en dispositivos con páginas de 16 KB
    // (Android 15+, teléfonos más nuevos) y evita el cierre al abrir.
    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Usa el keystore real si existe (Play Store); si no, firma de debug
            // para poder probar `--release` en desarrollo.
            signingConfig = if (hasReleaseKeystore) {
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
