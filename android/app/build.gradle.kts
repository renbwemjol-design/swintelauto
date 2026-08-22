plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // 🏆 NAMESPACE DE PRODUCTION DIRECTE : Totalement découplé de la maquette de laboratoire
    namespace = "com.swintel.production"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 🛠️ VERROU DE SÉCURITÉ : Activation du mécanisme de desugaring exigé par flutter_local_notifications [▲]
        isCoreLibraryDesugaringEnabled = true
        
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // 🏆 APPLICATION ID DE CRÊTE : Protège la V1-Beta contre tout risque d'écrasement matériel [▲]
        applicationId = "com.swintel.production"
        
        // Alignement automatique sur les variables de configuration de l'infrastructure Flutter
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // ⚙️ BRIDAGE MATÉRIEL ANDROID GO : Permet le fractionnement multidex pour les vieux processeurs [▲]
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Configuration de signature debug temporaire pour valider le 'flutter run --release' au goudron
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// 💥 RACCORDEMENT DES BINAIRES DE L'OS ANDROID
dependencies {
    // 🛠️ INJECTION D'USINE : Version 2.1.4 imposée pour la stabilité du SDK 36 sous la pluie de Nice [▲]
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
