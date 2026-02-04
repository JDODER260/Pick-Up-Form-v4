import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing config only if environment variables exist (GitHub Actions or local dev)
val keyAliasEnv = System.getenv("KEY_ALIAS")
val keyPasswordEnv = System.getenv("KEY_PASSWORD")
val storePasswordEnv = System.getenv("KEYSTORE_PASSWORD")
val storeFileEnv = System.getenv("KEYSTORE_FILE_PATH") // Path to keystore.jks

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
            // Use environment variables first (CI), fallback to local key.properties
            if (keyAliasEnv != null && keyPasswordEnv != null && storePasswordEnv != null && storeFileEnv != null) {
                keyAlias = keyAliasEnv
                keyPassword = keyPasswordEnv
                storePassword = storePasswordEnv
                storeFile = file(storeFileEnv)
            } else {
                // fallback for local development
                val keystoreProperties = Properties()
                val keystorePropertiesFile = rootProject.file("key.properties")
                if (keystorePropertiesFile.exists()) {
                    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
                }
                keyAlias = keystoreProperties["keyAlias"]?.toString()
                    ?: throw GradleException("keyAlias missing in key.properties")
                keyPassword = keystoreProperties["keyPassword"]?.toString()
                    ?: throw GradleException("keyPassword missing in key.properties")
                storePassword = keystoreProperties["storePassword"]?.toString()
                    ?: throw GradleException("storePassword missing in key.properties")
                storeFile = file(keystoreProperties["storeFile"]?.toString()
                    ?: throw GradleException("storeFile missing in key.properties"))
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
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
