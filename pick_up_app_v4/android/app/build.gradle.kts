import java.util.Base64
import java.io.File

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("kotlin-android")

    // ✅ MUST be applied (NO version, NO apply false)
    id("com.google.gms.google-services")
}

dependencies {
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.9.0"))

    // REQUIRED Firebase deps
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

android {
    namespace = "com.doublersharpening.pick_up_app_v4"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }


    kotlin {
        jvmToolchain(17)
    }

    defaultConfig {
        multiDexEnabled = true
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
                val keystoreFile = File("${project.projectDir}/pickup_delivery_release.jks")

                if (!keystoreFile.exists()) {
                    val decodedBytes = Base64.getDecoder().decode(keystoreBase64)
                    keystoreFile.writeBytes(decodedBytes)
                }

                storeFile = keystoreFile
            }

            if (
                envKeyAlias.isEmpty() ||
                envKeyPassword.isEmpty() ||
                envStorePassword.isEmpty() ||
                keystoreBase64.isEmpty()
            ) {
                logger.warn("Warning: Missing signing environment variables. Release signing may fail.")
            }
        }
    }


    buildTypes {
        getByName("release") {
            val keyAlias = System.getenv("KEY_ALIAS")
            val keyPassword = System.getenv("KEY_PASSWORD")
            val storePassword = System.getenv("STORE_PASSWORD")
            val keystoreBase64 = System.getenv("KEYSTORE_BASE64")

            if (
                !keyAlias.isNullOrEmpty() &&
                !keyPassword.isNullOrEmpty() &&
                !storePassword.isNullOrEmpty() &&
                !keystoreBase64.isNullOrEmpty()
            ) {
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
