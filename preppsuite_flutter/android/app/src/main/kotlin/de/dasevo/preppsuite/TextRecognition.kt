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
 * engine is made once and kept.
 */
class TextRecognition(private val context: Context, messenger: BinaryMessenger) {
    private companion object {
        const val CHANNEL = "de.dasevo.preppsuite/text_recognition"

        /** German first; English beside it for the English half of a library. */
        const val LANGUAGES = "deu+eng"

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

    /** Touched only on [worker]. */
    private var engine: TessBaseAPI? = null

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
            "support" -> worker.execute {
                val ready = runCatching { engine() != null }.getOrDefault(false)
                main.post { result.success(if (ready) "available" else "unsupported") }
            }
            "recognize" -> {
                val bgra = call.argument<ByteArray>("bgra")
                val width = call.argument<Int>("width") ?: 0
                val height = call.argument<Int>("height") ?: 0
                if (bgra == null || width <= 0 || height <= 0 ||
                    bgra.size < width.toLong() * height * 4
                ) {
                    result.error("arguments", "no page", null)
                    return
                }
                worker.execute {
                    try {
                        val api = engine() ?: throw IllegalStateException("no engine")
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

    /** The engine, made on first use from the data shipped in the APK. */
    private fun engine(): TessBaseAPI? {
        engine?.let { return it }
        val root = File(context.filesDir, DATA_FOLDER)
        val data = File(root, "tessdata").apply { mkdirs() }
        for (language in LANGUAGES.split('+')) {
            val target = File(data, "$language.traineddata")
            if (target.length() > 0) continue
            // Written beside and moved into place, so a copy cut short by a
            // closed app is never taken for a whole one.
            val partial = File(data, "$language.traineddata.part")
            context.assets.open("tessdata/$language.traineddata").use { input ->
                FileOutputStream(partial).use { output -> input.copyTo(output) }
            }
            if (!partial.renameTo(target)) return null
        }
        val api = TessBaseAPI()
        if (!api.init(root.absolutePath, LANGUAGES)) {
            api.recycle()
            return null
        }
        // A whole page with columns and headings, not one block of text:
        // Tesseract's API starts out assuming the latter.
        api.setPageSegMode(TessBaseAPI.PageSegMode.PSM_AUTO)
        engine = api
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
