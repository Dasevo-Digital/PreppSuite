package de.status403.ocrprobe

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.Bundle
import android.os.Debug
import android.os.ParcelFileDescriptor
import android.util.Log
import android.widget.TextView
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import com.google.android.gms.tasks.Tasks
import java.io.File
import kotlin.concurrent.thread

/**
 * Measures what an offline text recognition costs on this phone.
 *
 * The counterpart of the macOS probe, and deliberately the same shape:
 * render a PDF page the way the app would, hand the bitmap to the
 * platform's own recognition, write down what it cost and what came out.
 * Nothing here is part of PreppSuite.
 *
 *   adb push <datei.pdf> /sdcard/Download/probe.pdf
 *   adb shell am start -n de.status403.ocrprobe/.MeasureActivity \
 *       -e pdf /sdcard/Download/probe.pdf -e pages 26 -e dpi 200
 *   adb shell run-as de.status403.ocrprobe cat files/ocr-probe.jsonl
 *
 * The numbers that matter are the memory ones. On macOS the recognition
 * needed 600 MB before the first page was done, and that is the figure a
 * phone has to be held against.
 */
class MeasureActivity : Activity() {

    private lateinit var output: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        output = TextView(this)
        output.textSize = 11f
        setContentView(output)

        val path = intent.getStringExtra("pdf") ?: "/sdcard/Download/probe.pdf"
        val pages = intent.getStringExtra("pages")?.toIntOrNull() ?: 10
        val dpi = intent.getStringExtra("dpi")?.toIntOrNull() ?: 200

        thread { measure(path, pages, dpi) }
    }

    private fun measure(path: String, maxPages: Int, dpi: Int) {
        val report = File(filesDir, "ocr-probe.jsonl")
        report.writeText("")

        val file = File(path)
        if (!file.exists()) {
            say(report, """{"error":"pdf not found","path":"$path"}""")
            return
        }

        // Before anything is loaded, so the model's own cost is visible.
        val baseline = Debug.getPss()

        val descriptor = ParcelFileDescriptor.open(
            file, ParcelFileDescriptor.MODE_READ_ONLY
        )
        val renderer = PdfRenderer(descriptor)
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

        var renderTotal = 0L
        var ocrTotal = 0L
        var characters = 0
        var peak = baseline
        val count = minOf(maxPages, renderer.pageCount)

        for (index in 0 until count) {
            val page = renderer.openPage(index)
            // A PDF point is 1/72 inch; the page's own size is in points.
            val scale = dpi / 72.0
            val width = (page.width * scale).toInt()
            val height = (page.height * scale).toInt()

            val renderStart = System.nanoTime()
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            bitmap.eraseColor(Color.WHITE)
            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
            page.close()
            val renderMillis = (System.nanoTime() - renderStart) / 1_000_000

            val ocrStart = System.nanoTime()
            val text = try {
                Tasks.await(recognizer.process(InputImage.fromBitmap(bitmap, 0))).text
            } catch (error: Exception) {
                Log.w("ocr-probe", "page ${index + 1} failed", error)
                ""
            }
            val ocrMillis = (System.nanoTime() - ocrStart) / 1_000_000

            // Freed by hand rather than left to the collector: the whole
            // question here is what the peak is.
            bitmap.recycle()

            val pss = Debug.getPss()
            if (pss > peak) peak = pss
            renderTotal += renderMillis
            ocrTotal += ocrMillis
            characters += text.length

            say(
                report,
                """{"page":${index + 1},"pixels":"${width}x${height}",""" +
                    """"render_ms":$renderMillis,"ocr_ms":$ocrMillis,""" +
                    """"characters":${text.length},"pss_kb":$pss}"""
            )
        }

        renderer.close()
        descriptor.close()
        recognizer.close()

        say(
            report,
            """{"file":"${file.name}","pages_in_document":${renderer.pageCount},""" +
                """"pages_measured":$count,"dpi":$dpi,""" +
                """"render_ms_total":$renderTotal,"ocr_ms_total":$ocrTotal,""" +
                """"characters_total":$characters,""" +
                """"pss_before_kb":$baseline,"pss_peak_kb":$peak}"""
        )
    }

    private fun say(report: File, line: String) {
        Log.i("ocr-probe", line)
        report.appendText(line + "\n")
        runOnUiThread { output.append(line + "\n\n") }
    }
}
