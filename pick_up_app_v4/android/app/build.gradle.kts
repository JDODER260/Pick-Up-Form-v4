import java.util.Properties
import java.io.FileInputStream

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

    kotlinOptions {
        jvmTarget = "17"
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
            // Get values from environment variables (which will be set from GitHub Secrets)
            keyAlias = System.getenv("KEY_ALIAS") ?: ""
            keyPassword = System.getenv("KEY_PASSWORD") ?: ""
            
            // For storeFile, you need to create the keystore file from a base64 encoded string
            val keystoreBase64 = System.getenv("KEYSTORE_BASE64")
            if (keystoreBase64 != null) {
                // Create keystore file in a temporary location
                val keystoreFile = File("${project.buildDir}/tmp/keystore.jks")
                keystoreFile.parentFile.mkdirs()
                
                // Decode base64 and write to file
                val keystoreBytes = java.util.Base64.getDecoder().decode(keystoreBase64)
                keystoreFile.writeBytes(keystoreBytes)
                
                storeFile = keystoreFile
            }
            
            storePassword = System.getenv("STORE_PASSWORD") ?: ""
            
            // Validate that all required values are present
            if (keyAlias.isEmpty() || keyPassword.isEmpty() || storePassword.isEmpty()) {
                logger.warn("Warning: Not all signing config values are available. Release signing may not work.")
            }
        }
    }

    buildTypes {
        getByName("release") {
            // Only apply signing config if all required values are available
            val keyAlias = System.getenv("KEY_ALIAS")
            val keyPassword = System.getenv("KEY_PASSWORD")
            val storePassword = System.getenv("STORE_PASSWORD")
            val keystoreBase64 = System.getenv("KEYSTORE_BASE64")
            
            if (keyAlias != null && keyPassword != null && storePassword != null && keystoreBase64 != null) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                logger.warn("Release build will not be signed due to missing secrets")
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
