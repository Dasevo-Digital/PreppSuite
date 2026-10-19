package de.dasevo.preppsuite

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.googlecode.tesseract.android.TessBaseAPI
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

/**
 * Reads the text on a scanned page with Tesseract (#66).
 *
 * Tesseract rather than ML Kit, which was measured first and reads a
 * little better: ML Kit sends usage figures to Google by its own terms,
 * and this app sends nothing it does not have to. Tesseract runs on the
 * device and talks to nobody.
 *
 * The page arrives as BGRA pixels drawn by PDFium on the Dart side, the
 * same on every platform; it is turned grey here, which is all Tesseract
 * reads anyway. One engine, on one thread of its own: Tesseract's API is
 * not thread-safe, and loading its language data is the slow part, so the
 * engine is kept for as long as the same languages are asked for.
 *
 * German and English come with the APK. Other languages' data is fetched
 * by the app into the same folder (#205, `tesseract_data.dart`), which is
 * why that folder can be asked for.
 */
class TextRecognition(private val context: Context, messenger: BinaryMessenger) {
    private companion object {
        const val CHANNEL = "de.dasevo.preppsuite/text_recognition"

        /** German first; English beside it for the English half of a library. */
        const val LANGUAGES = "deu+eng"

        /** The data in the APK; anything else has to have been fetched. */
        val SHIPPED = setOf("deu", "eng")

        /**
         * Where the language data is copied to. Named after the data's own
         * version, so that new data in a later app lands beside the old
         * rather than being mistaken for it.
         */
        const val DATA_FOLDER = "tesseract/tessdata_fast-4.1.0"
    }

    private val channel = MethodChannel(messenger, CHANNEL)
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /** Touched only on [worker]: the engine and what it was made for. */
    private var engine: TessBaseAPI? = null
    private var engineLanguages: String? = null

    init {
        channel.setMethodCallHandler { call, result -> handle(call, result) }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        worker.execute {
            engine?.recycle()
            engine = null
        }
        worker.shutdown()
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "tessdataPath" -> worker.execute {
                val path = runCatching { dataFolder().absolutePath }.getOrNull()
                main.post { result.success(path) }
            }
            "support" -> {
                val languages = call.argument<String>("tesseract") ?: LANGUAGES
                worker.execute {
                    val answer = when {
                        !hasData(languages) -> "needsLanguageData"
                        runCatching { engine(languages) != null }.getOrDefault(false) ->
                            "available"
                        else -> "unsupported"
                    }
                    main.post { result.success(answer) }
                }
            }
            "recognize" -> {
                val bgra = call.argument<ByteArray>("bgra")
                val width = call.argument<Int>("width") ?: 0
                val height = call.argument<Int>("height") ?: 0
                val languages = call.argument<String>("tesseract") ?: LANGUAGES
                if (bgra == null || width <= 0 || height <= 0 ||
                    bgra.size < width.toLong() * height * 4
                ) {
                    result.error("arguments", "no page", null)
                    return
                }
                worker.execute {
                    try {
                        val api = engine(languages) ?: throw IllegalStateException("no engine")
                        api.setImage(grey(bgra, width, height), width, height, 1, width)
                        val text = api.getUTF8Text() ?: ""
                        api.clear()
                        main.post { result.success(text) }
                    } catch (error: Throwable) {
                        main.post { result.error("recognition", error.message, null) }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun dataFolder(): File =
        File(File(context.filesDir, DATA_FOLDER), "tessdata").apply { mkdirs() }

    /** Whether every one of [languages] is shipped or has been fetched. */
    private fun hasData(languages: String): Boolean =
        languages.split('+').all {
            it in SHIPPED || File(dataFolder(), "$it.traineddata").length() > 0
        }

    /**
     * The engine for [languages], made the first time they are asked for:
     * the shipped data is copied out of the APK, fetched data is already in
     * place. A different set of languages replaces the engine rather than
     * adding one, since each holds its models in memory.
     */
    private fun engine(languages: String): TessBaseAPI? {
        if (engineLanguages == languages) engine?.let { return it }
        engine?.recycle()
        engine = null
        engineLanguages = null
        val root = File(context.filesDir, DATA_FOLDER)
        val data = dataFolder()
        for (language in languages.split('+')) {
            val target = File(data, "$language.traineddata")
            if (target.length() > 0) continue
            if (language !in SHIPPED) return null
            // Written beside and moved into place, so a copy cut short by a
            // closed app is never taken for a whole one.
            val partial = File(data, "$language.traineddata.part")
            context.assets.open("tessdata/$language.traineddata").use { input ->
                FileOutputStream(partial).use { output -> input.copyTo(output) }
            }
            if (!partial.renameTo(target)) return null
        }
        val api = TessBaseAPI()
        if (!api.init(root.absolutePath, languages)) {
            api.recycle()
            return null
        }
        // A whole page with columns and headings, not one block of text:
        // Tesseract's API starts out assuming the latter.
        api.setPageSegMode(TessBaseAPI.PageSegMode.PSM_AUTO)
        engine = api
        engineLanguages = languages
        return api
    }

    /** BGRA to eight-bit grey, by the usual luminance weights. */
    private fun grey(bgra: ByteArray, width: Int, height: Int): ByteArray {
        val out = ByteArray(width * height)
        var j = 0
        for (i in out.indices) {
            val blue = bgra[j].toInt() and 0xFF
            val green = bgra[j + 1].toInt() and 0xFF
            val red = bgra[j + 2].toInt() and 0xFF
            out[i] = ((red * 299 + green * 587 + blue * 114) / 1000).toByte()
            j += 4
        }
        return out
    }
}
