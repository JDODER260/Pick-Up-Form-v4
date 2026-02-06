import java.util.Base64
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.doublersharpening.pick_up_app_v4"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        jvmToolchain(17)
    }

    defaultConfig {
        applicationId = "com.doublersharpening.pick_up_app_v4"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val envKeyAlias = System.getenv("KEY_ALIAS") ?: ""
            val envKeyPassword = System.getenv("KEY_PASSWORD") ?: ""
            val envStorePassword = System.getenv("STORE_PASSWORD") ?: ""
            val keystoreBase64 = System.getenv("KEYSTORE_BASE64") ?: ""

            keyAlias = envKeyAlias
            keyPassword = envKeyPassword
            storePassword = envStorePassword

            if (keystoreBase64.isNotEmpty()) {
                // Put keystore inside 'app' folder to avoid Gradle path issues
                val keystoreFile = File("${project.projectDir}/app/pickup_delivery_release.jks")
                if (!keystoreFile.exists()) {
                    keystoreFile.writeBytes(Base64.getDecoder().decode(keystoreBase64))
                }
                storeFile = keystoreFile
            }

            if (envKeyAlias.isEmpty() || envKeyPassword.isEmpty() || envStorePassword.isEmpty() || keystoreBase64.isEmpty()) {
                logger.warn("Warning: Missing signing environment variables. Release signing may fail.")
            }
        }
    }


    buildTypes {
        getByName("release") {
            // Apply signing config only if all env vars exist
            val keyAlias = System.getenv("KEY_ALIAS")
            val keyPassword = System.getenv("KEY_PASSWORD")
            val storePassword = System.getenv("STORE_PASSWORD")
            val keystoreBase64 = System.getenv("KEYSTORE_BASE64")

            if (!keyAlias.isNullOrEmpty() &&
                !keyPassword.isNullOrEmpty() &&
                !storePassword.isNullOrEmpty() &&
                !keystoreBase64.isNullOrEmpty()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                logger.warn("Release build will not be signed due to missing environment variables.")
            }

            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
