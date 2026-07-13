plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // 👈 أضف هذا السطر هنا بدقة
}

android {
    namespace = "com.AbdoFawzi.redops_hub"
    compileSdk = 36 // flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.AbdoFawzi.redops_hub"
        minSdk = 24 // flutter.minSdkVersion
        targetSdk = 36 // flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.fragment:fragment-ktx:1.7.1")
    implementation("androidx.multidex:multidex:2.0.1")
}
