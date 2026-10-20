# Tesseract4Android (#66): the native library calls back into these classes
# by name, so they must survive shrinking with their members.
-keep class com.googlecode.tesseract.android.** { *; }
-keep class com.googlecode.leptonica.android.** { *; }

# shared_preferences_android 2.5 calls its Kotlin code from Dart over JNI
# (package:jni), and both sides find classes and members by name: the
# plugin's suspend functions by a signature with
# kotlin.coroutines.Continuation, package:jni the coroutine and Result
# classes below. Renamed or removed by R8, every read of the settings
# fails, and 2.6.0 and 2.6.1 on Android opened on "the household cannot
# be loaded" (#206; Famio 2.0.8 had the same). release.sh checks the
# signature in the package and starts it on the emulator.
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt* { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.Unit { *; }
