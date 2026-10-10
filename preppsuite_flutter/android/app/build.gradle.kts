import java.io.FileInputStream
import java.util.Properties

// Release signing is read from android/key.properties, which is git-ignored
// and holds the path to a keystore kept outside the repository. It is
// deliberately optional: without it the release build falls back to the
// debug key, so a fresh clone can still run `flutter build apk --release`
// to try the app out. What it must never do is silently produce a
// debug-signed APK for distribution — see README, "Android weitergeben".
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasReleaseKeystore = keystorePropertiesFile.exists()

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "de.dasevo.preppsuite"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications uses java.time, which only exists from
        // Android 8 on; desugaring back-fills it for the older versions we
        // still support (minSdk 24). Without this the release build fails
        // outright.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "de.dasevo.preppsuite"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // arm64 is every Android phone of the last several years, arm32 the
    // older ones minSdk 24 still admits. x86 and x86_64 are the emulator
    // and reach no device this app is handed to.
    //
    // It takes both halves. `flutter build --target-platform` governs
    // Flutter's own engine libraries and took the package from 96.7 MB to
    // 69.8 MB; what it leaves behind are the prebuilt .so files plugins
    // ship inside their AARs — ML Kit's barcode reader is 5.9 MB of
    // exactly that, and libzstandard, libdartjni and the camera helpers
    // add the rest. `defaultConfig.ndk.abiFilters` does not remove them
    // here: the Flutter Gradle plugin sets that property itself, and a
    // value written in defaultConfig does not survive. Excluding at the
    // packaging step does, and is checked afterwards in
    // tool/android_release.sh. Together: 96.7 MB -> 63.1 MB.

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                // minSdk is 24, so v2 is the oldest scheme any device we
                // support reads, and v1 (JAR signing) buys nothing but size.
                // v3 is what carries the rotation proof that lets the key
                // below replace the debug key on an existing install.
                //
                // Careful: the Android Gradle Plugin cannot attach a
                // SigningCertificateLineage, so the v3 block it writes names
                // this key alone. Every device still holding a 0.10.0 install
                // rejects that. tool/android_release.sh re-signs the output
                // with android/signing-lineage.bin, and only that script's
                // APK may be handed out.
                enableV1Signing = false
                enableV2Signing = true
                enableV3Signing = true
                enableV4Signing = false
            }
        }
    }

    buildTypes {
        release {
            // Tesseract's Java side is reached from its native code by name,
            // and an AAR without rules of its own would be shrunk away.
            proguardFiles("proguard-rules.pro")
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Fine for trying the app out, useless for handing it on:
                // the debug keystore's password is the publicly known
                // "android", so anyone could sign a forged update.
                logger.warn(
                    "PreppSuite: no android/key.properties — release APK is " +
                        "signed with the debug key and must not be distributed."
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

// Debug builds must retain the emulator ABI, including native plugin libs.
// Distribution keeps exactly the existing ARM-only release packaging.
androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        variant.packaging.jniLibs.excludes.addAll(
            setOf("**/x86/**", "**/x86_64/**")
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // The shared-folder sync reaches the folder the user picked through
    // the Storage Access Framework — see MainActivity. DocumentFile is the
    // readable way to walk a content:// tree.
    implementation("androidx.documentfile:documentfile:1.0.1")
    // The biometric prompt behind the app lock (#143) needs an AppCompat
    // launch theme, or it crashes on Android 8 and older. Named here rather
    // than left to whichever plugin happens to pull it in.
    implementation("androidx.appcompat:appcompat:1.7.0")
    // Reads scanned pages on the device (#66): Tesseract 5.5.1 with
    // Leptonica. Not ML Kit, which sends usage figures to Google. Its
    // language data is in src/main/assets/tessdata, see
    // third_party/tessdata_fast.
    implementation("cz.adaptech.tesseract4android:tesseract4android:4.9.0")
}

// Flutter 3.44 currently writes the dev-only integration_test plugin into
// GeneratedPluginRegistrant.java for every Android variant, but does not put
// that plugin on a release variant's Java classpath.  Remove precisely that
// generated block immediately before release compilation. Debug and
// integration-test variants keep it, so device tests still register their
// harness normally.
tasks.matching { it.name == "compileReleaseJavaWithJavac" }.configureEach {
    doFirst {
        val registrant = file(
            "src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java",
        )
        if (!registrant.exists()) return@doFirst
        val source = registrant.readText()
        val start = "    try {\n" +
            "      flutterEngine.getPlugins().add(" +
            "new dev.flutter.plugins.integration_test.IntegrationTestPlugin());"
        val startIndex = source.indexOf(start)
        if (startIndex < 0) return@doFirst
        val endIndex = source.indexOf("    }\n", startIndex)
        if (endIndex < 0) {
            throw GradleException("Could not isolate the generated integration-test registration.")
        }
        registrant.writeText(source.removeRange(startIndex, endIndex + "    }\n".length))
    }
}

flutter {
    source = "../.."
}
