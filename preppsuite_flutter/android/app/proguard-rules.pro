# Tesseract4Android (#66): the native library calls back into these classes
# by name, so they must survive shrinking with their members.
-keep class com.googlecode.tesseract.android.** { *; }
-keep class com.googlecode.leptonica.android.** { *; }
