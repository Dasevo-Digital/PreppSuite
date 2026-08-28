allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// file_picker 8.3.7 compiles against android-34, while one of its own
// dependencies (flutter_plugin_android_lifecycle) demands 36 — which fails
// the build outright. Upgrading is not an option: the package is pinned
// below 9.x because newer versions break file picking on macOS, and the
// reason is written out in pubspec.yaml. 8.3.7 is the last 8.x release, so
// there is nothing to move to inside the pin.
//
// Raising the value for this one module is the narrowest fix; every other
// plugin keeps whatever it declares. Done by reflection because the Android
// Gradle Plugin's types are not on this script's classpath.
subprojects {
    if (name == "file_picker") {
        afterEvaluate {
            val androidExtension = extensions.findByName("android")
            val setCompileSdk = androidExtension?.javaClass?.methods?.firstOrNull {
                it.name == "compileSdkVersion" &&
                    it.parameterTypes.size == 1 &&
                    it.parameterTypes[0] == Int::class.javaPrimitiveType
            }
            setCompileSdk?.invoke(androidExtension, 36)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
