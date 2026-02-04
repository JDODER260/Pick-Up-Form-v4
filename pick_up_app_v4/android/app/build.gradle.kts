import java.util.Base64
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
            // Get values from environment variables (which will be set from GitHub Secrets)
            val envKeyAlias = System.getenv("KEY_ALIAS") ?: ""
            val envKeyPassword = System.getenv("KEY_PASSWORD") ?: ""
            val envStorePassword = System.getenv("STORE_PASSWORD") ?: ""
            
            keyAlias = envKeyAlias
            keyPassword = envKeyPassword
            storePassword = envStorePassword
            
            // For storeFile, you need to create the keystore file from a base64 encoded string
            val keystoreBase64 = System.getenv("KEYSTORE_BASE64")
            if (keystoreBase64 != null && keystoreBase64.isNotEmpty()) {
                // Create keystore file in a temporary location
                val keystoreFile = File("${project.layout.buildDirectory.get()}/tmp/keystore.jks")
                keystoreFile.parentFile.mkdirs()
                
                // Decode base64 and write to file
                val keystoreBytes = Base64.getDecoder().decode(keystoreBase64)
                keystoreFile.writeBytes(keystoreBytes)
                
                storeFile = keystoreFile
            }
            
            // Validate that all required values are present
            if (envKeyAlias.isEmpty() || envKeyPassword.isEmpty() || envStorePassword.isEmpty() || keystoreBase64.isNullOrEmpty()) {
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
            
            if (!keyAlias.isNullOrEmpty() && 
                !keyPassword.isNullOrEmpty() && 
                !storePassword.isNullOrEmpty() && 
                !keystoreBase64.isNullOrEmpty()) {
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
