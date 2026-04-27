plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.alrafeeg_chat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // في Kotlin DSL نستخدم isCoreLibraryDesugaringEnabled
        isCoreLibraryDesugaringEnabled = true 
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        // الطريقة الصحيحة لتعريف jvmTarget في ملفات kts
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.alrafeeg_chat"
        minSdk = 21 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // تأكد من استخدام الأقواس في ملفات kts
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}