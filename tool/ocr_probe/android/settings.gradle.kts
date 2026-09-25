// Ein eigenständiges Messprojekt, kein Teil von PreppSuite.
// Es hängt bewusst nicht am Flutter-Build: was gemessen wird, ist die
// Texterkennung von Android, nicht die App darum herum.
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.application") version "9.0.1" apply false
}

rootProject.name = "ocr-probe"
include(":app")
