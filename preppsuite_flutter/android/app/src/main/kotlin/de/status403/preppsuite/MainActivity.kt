package de.status403.preppsuite

import android.content.Intent
import android.net.Uri
import android.os.ParcelFileDescriptor
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.util.concurrent.Executors

/**
 * Everything the app needs from storage the user picked.
 *
 * Android has not let an app open an arbitrary path since scoped storage:
 * a picked folder or file comes back as a `content://` URI that only the
 * Storage Access Framework can read, and `dart:io` cannot touch one at
 * all. Two features depend on that — the shared-folder sync and the
 * offline map archive — so both go through here.
 *
 * The permission is taken as *persistable* in both cases, which is the
 * part that makes this worth doing: it survives a restart, so the folder
 * and the map are picked once rather than every launch.
 */
class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "preppsuite/storage"
        const val PICK_FOLDER_REQUEST = 8451
        const val PICK_FILE_REQUEST = 8452
    }

    /** Set while a picker is open; there is only ever one. */
    private var pendingPick: MethodChannel.Result? = null

    /**
     * Open descriptors for files being read in ranges, by URI.
     *
     * A map archive is gigabytes and is read a few kilobytes at a time,
     * once per tile. Reopening it for every read would be the difference
     * between a map that pans and one that stutters.
     */
    private val openFiles = mutableMapOf<String, ParcelFileDescriptor>()

    /**
     * Reads happen here rather than on the main thread: a map being panned
     * asks for tiles continuously, and file I/O in the middle of that is
     * what turns smooth scrolling into jank.
     */
    private val fileReads = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pick" -> pick(Intent.ACTION_OPEN_DOCUMENT_TREE, PICK_FOLDER_REQUEST, result)
            "pickFile" -> pick(Intent.ACTION_OPEN_DOCUMENT, PICK_FILE_REQUEST, result)
            "openFile" -> result.success(openFile(call.argument("uri")!!))
            "readRange" -> readRange(
                call.argument("uri")!!,
                (call.argument<Number>("offset")!!).toLong(),
                (call.argument<Number>("length")!!).toInt(),
                result,
            )
            "closeFile" -> {
                closeFile(call.argument("uri")!!)
                result.success(null)
            }
            "ensureWritable" -> result.success(ensureWritable(call.argument("uri")!!))
            "list" -> result.success(
                list(call.argument("uri")!!, call.argument("path")!!)
            )
            "read" -> result.success(
                read(call.argument("uri")!!, call.argument("path")!!)
            )
            "write" -> {
                write(
                    call.argument("uri")!!,
                    call.argument("path")!!,
                    call.argument("contents")!!,
                )
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun pick(action: String, requestCode: Int, result: MethodChannel.Result) {
        pendingPick?.success(null)
        pendingPick = result

        val intent = Intent(action).addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
        )
        if (action == Intent.ACTION_OPEN_DOCUMENT) {
            // The picker has no notion of a .pmtiles file, so it shows
            // everything and the archive is checked after it is opened.
            intent.type = "*/*"
            intent.addCategory(Intent.CATEGORY_OPENABLE)
        }
        startActivityForResult(intent, requestCode)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        val isFolder = requestCode == PICK_FOLDER_REQUEST
        if (!isFolder && requestCode != PICK_FILE_REQUEST) return

        val result = pendingPick ?: return
        pendingPick = null

        val picked = data?.data
        if (resultCode != RESULT_OK || picked == null) {
            result.success(null)
            return
        }

        // Without this the grant lasts only as long as this process, and
        // whatever was picked would have to be picked again on every
        // launch. A file is only ever read, so read is all it asks for.
        contentResolver.takePersistableUriPermission(
            picked,
            if (isFolder) {
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            } else {
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            },
        )

        val document = if (isFolder) {
            DocumentFile.fromTreeUri(this, picked)
        } else {
            DocumentFile.fromSingleUri(this, picked)
        }

        result.success(
            mapOf(
                "uri" to picked.toString(),
                "label" to (document?.name ?: picked.lastPathSegment.orEmpty()),
            ),
        )
    }

    // --- Ranged reads, for the offline map archive ----------------------

    private fun openFile(uri: String): Boolean {
        closeFile(uri)
        return runCatching {
            val descriptor = contentResolver.openFileDescriptor(Uri.parse(uri), "r")
                ?: return false
            openFiles[uri] = descriptor
            true
        }.getOrDefault(false)
    }

    private fun readRange(
        uri: String,
        offset: Long,
        length: Int,
        result: MethodChannel.Result,
    ) {
        val descriptor = openFiles[uri]
        if (descriptor == null) {
            result.error("not-open", "no open descriptor for $uri", null)
            return
        }

        fileReads.execute {
            val outcome = runCatching {
                // A fresh stream per read: the descriptor is shared, and a
                // position set on one channel is visible to the others.
                FileInputStream(descriptor.fileDescriptor).channel.use { channel ->
                    val buffer = ByteBuffer.allocate(length)
                    var position = offset
                    while (buffer.hasRemaining()) {
                        val read = channel.read(buffer, position)
                        if (read <= 0) break
                        position += read
                    }
                    buffer.array().copyOf(buffer.position())
                }
            }
            runOnUiThread {
                outcome.fold(
                    onSuccess = { result.success(it) },
                    onFailure = { result.error("read-failed", it.message, null) },
                )
            }
        }
    }

    private fun closeFile(uri: String) {
        openFiles.remove(uri)?.let { runCatching { it.close() } }
    }

    override fun onDestroy() {
        openFiles.values.forEach { runCatching { it.close() } }
        openFiles.clear()
        fileReads.shutdown()
        super.onDestroy()
    }

    /**
     * Whether the tree is still ours to write, creating PreppSuite's own
     * subdirectory while we are at it.
     *
     * The persisted-permission check is the one that matters: a grant is
     * dropped when the app is reinstalled, or when the user revokes it in
     * the system settings, and the folder then looks perfectly fine right
     * up until the first write fails.
     */
    private fun ensureWritable(uri: String): Boolean {
        val tree = Uri.parse(uri)
        val granted = contentResolver.persistedUriPermissions.any {
            it.uri == tree && it.isWritePermission
        }
        if (!granted) return false

        val root = DocumentFile.fromTreeUri(this, tree) ?: return false
        return root.canWrite() &&
            resolveDirectory(root, listOf("preppsuite", "devices"), create = true) != null
    }

    private fun list(uri: String, path: String): List<String> {
        val directory = directoryAt(uri, path, create = false) ?: return emptyList()
        return directory.listFiles().filter { it.isFile }.mapNotNull { it.name }
    }

    private fun read(uri: String, path: String): String? {
        val segments = path.split('/')
        val directory = directoryAt(uri, segments.dropLast(1).joinToString("/"), create = false)
            ?: return null
        val file = directory.findFile(segments.last()) ?: return null
        if (!file.isFile) return null

        return runCatching {
            contentResolver.openInputStream(file.uri)?.bufferedReader()?.use { it.readText() }
        }.getOrNull()
    }

    /**
     * Overwrites in place, truncating first.
     *
     * Unlike the desktop implementation this is not a rename, so a reader
     * can in principle catch a half-written file. That costs one file for
     * one run — the snapshot fails to parse and is skipped — because the
     * alternative on SAF is delete-then-rename, whose window is a file
     * that is missing entirely, and whose display names the provider is
     * free to rewrite.
     */
    private fun write(uri: String, path: String, contents: String) {
        val segments = path.split('/')
        val directory = directoryAt(uri, segments.dropLast(1).joinToString("/"), create = true)
            ?: return
        val name = segments.last()
        val file = directory.findFile(name)
            ?: directory.createFile("application/json", name)
            ?: return

        contentResolver.openOutputStream(file.uri, "wt")?.use {
            it.write(contents.toByteArray(Charsets.UTF_8))
        }
    }

    private fun directoryAt(uri: String, path: String, create: Boolean): DocumentFile? {
        // A handle that is not (or no longer) a document tree, such as one
        // restored from another platform, is simply not there.
        val root = try {
            DocumentFile.fromTreeUri(this, Uri.parse(uri))
        } catch (e: IllegalArgumentException) {
            null
        } ?: return null
        val segments = path.split('/').filter { it.isNotEmpty() }
        return resolveDirectory(root, segments, create)
    }

    private fun resolveDirectory(
        root: DocumentFile,
        segments: List<String>,
        create: Boolean,
    ): DocumentFile? {
        var current = root
        for (segment in segments) {
            val existing = current.findFile(segment)
            current = when {
                existing != null && existing.isDirectory -> existing
                existing != null -> return null
                create -> current.createDirectory(segment) ?: return null
                else -> return null
            }
        }
        return current
    }
}
