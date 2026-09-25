plugins {
    // Seit AGP 9 bringt das Android-Plugin Kotlin selbst mit; das
    // separate Kotlin-Plugin wird ausdruecklich abgelehnt.
    id("com.android.application")
}

android {
    namespace = "de.status403.ocrprobe"
    compileSdk = 36

    defaultConfig {
        applicationId = "de.status403.ocrprobe"
        // Dasselbe Minimum wie PreppSuite, damit die Messung für dieselben
        // Geräte gilt, für die die App gebaut wird.
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            // Mit dem Debug-Schlüssel, damit ein `adb install` genügt.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Das mitgelieferte Modell, nicht die Variante über die
    // Play-Dienste: gemessen werden soll, was ohne Netz und ohne Google
    // auf dem Gerät läuft.
    implementation("com.google.mlkit:text-recognition:16.0.1")
}
