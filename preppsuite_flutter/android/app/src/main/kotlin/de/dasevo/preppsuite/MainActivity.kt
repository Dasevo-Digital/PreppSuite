package de.dasevo.preppsuite

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.ParcelFileDescriptor
import android.provider.DocumentsContract
import android.provider.Settings
import android.system.Os
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

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
 * and the map are picked once rather than every launch. A file picked for
 * once, a backup to restore, is not kept, and a file the app no longer
 * remembers is given back (`release`, #410): Android keeps only so many.
 *
 * A FragmentActivity because the biometric prompt of the app lock is a
 * fragment (#143); everything above works the same on it.
 */
class MainActivity : FlutterFragmentActivity() {
    private companion object {
        const val CHANNEL = "preppsuite/storage"
        const val NOTIFICATIONS_CHANNEL = "preppsuite/notifications"
        const val PICK_FOLDER_REQUEST = 8451
        const val PICK_FILE_REQUEST = 8452
    }

    /** Set while a picker is open; there is only ever one. */
    private var pendingPick: MethodChannel.Result? = null

    /** Whether the file being picked is to be reachable after a restart. */
    private var pendingKeep = true

    /**
     * Open descriptors for files being read in ranges, by reader token.
     *
     * A map archive is gigabytes and is read a few kilobytes at a time,
     * once per tile. Reopening it for every read would be the difference
     * between a map that pans and one that stutters.
     */
    private val openFiles = mutableMapOf<String, ParcelFileDescriptor>()

    /**
     * Folder work happens here rather than on the main thread (#376, #410):
     * every answer from a document provider is a binder call, and one in
     * the cloud may first have to fetch what it is asked for. One thread,
     * so a read and a write of one file keep the order Dart asked in.
     */
    private val fileReads = Executors.newSingleThreadExecutor()

    /**
     * Ranged reads of open archives, on a thread of their own (#410): a map
     * being panned asks for tiles continuously, and behind a run through
     * the household's pictures each tile waited for the folder.
     */
    private val rangeReads = Executors.newSingleThreadExecutor()

    /** Reads scanned pages (#66); see TextRecognition. */
    private var textRecognition: TextRecognition? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATIONS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openChannelSettings" ->
                        result.success(openChannelSettings(call.argument("channel")!!))
                    else -> result.notImplemented()
                }
            }
        textRecognition =
            TextRecognition(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        textRecognition?.dispose()
        textRecognition = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    /**
     * Opens the system settings of one notification channel (#264).
     *
     * Whether a channel may come through "Do not disturb" is the user's to
     * decide, there; an app may only set it with access to the whole
     * policy. Channels exist from Android 8 on; before that there is
     * nothing to open, and the app's notification settings are the
     * nearest thing.
     */
    private fun openChannelSettings(channel: String): Boolean {
        val intent =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    .putExtra(Settings.EXTRA_CHANNEL_ID, channel)
            } else {
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                    .setData(Uri.fromParts("package", packageName, null))
            }
        return try {
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pick" -> pick(Intent.ACTION_OPEN_DOCUMENT_TREE, PICK_FOLDER_REQUEST, result)
            "pickFile" -> pick(
                Intent.ACTION_OPEN_DOCUMENT,
                PICK_FILE_REQUEST,
                result,
                keep = call.argument<Boolean>("keep") ?: true,
            )
            "release" -> {
                val uri = call.argument<String>("uri")!!
                fileReads.execute {
                    val released = runCatching { release(uri) }.getOrDefault(false)
                    runOnUiThread { result.success(released) }
                }
            }
            "openFile" -> openFile(call.argument("uri")!!, call.argument("fileToken"), result)
            "readRange" -> readRange(
                call.argument<String>("fileToken") ?: call.argument("uri")!!,
                (call.argument<Number>("offset")!!).toLong(),
                (call.argument<Number>("length")!!).toInt(),
                result,
            )
            "closeFile" -> {
                closeFile(call.argument<String>("fileToken") ?: call.argument("uri")!!)
                result.success(null)
            }
            // Off the main thread as well (#410): every two minutes, and
            // each answer is a binder call to a provider that may be slow.
            "ensureWritable" -> {
                val uri = call.argument<String>("uri")!!
                fileReads.execute {
                    val outcome = runCatching { ensureWritable(uri) }
                    runOnUiThread {
                        outcome.fold(
                            onSuccess = { result.success(it) },
                            onFailure = { result.error("error", it.message, null) },
                        )
                    }
                }
            }
            // Off the main thread, as reads are (#376): a folder with the
            // household's pictures in it holds hundreds of files, and the
            // provider answers each question with a binder call.
            "list" -> {
                val uri = call.argument<String>("uri")!!
                val path = call.argument<String>("path")!!
                fileReads.execute {
                    val names = try {
                        list(uri, path)
                    } catch (_: Exception) {
                        emptyList()
                    }
                    runOnUiThread { result.success(names) }
                }
            }
            "read" -> fileReads.execute {
                try {
                    val text = read(call.argument("uri")!!, call.argument("path")!!,
                        call.argument<Int>("maxBytes") ?: 64 * 1024 * 1024)
                    runOnUiThread { result.success(text) }
                } catch (_: ReadTooLarge) {
                    runOnUiThread { result.error("read-too-large", "File exceeds the read limit.", null) }
                } catch (_: Exception) {
                    // Not null: null says the file is not there, and the
                    // caller may then write a new one over it.
                    runOnUiThread { result.error("read-failed", "The file could not be read.", null) }
                }
            }
            // On the same thread as reads, so a read and a write of one file
            // keep the order Dart asked for them in.
            "write" -> {
                val uri = call.argument<String>("uri")!!
                val path = call.argument<String>("path")!!
                val contents = call.argument<String>("contents")!!
                fileReads.execute {
                    try {
                        write(uri, path, contents)
                        runOnUiThread { result.success(null) }
                    } catch (_: Exception) {
                        runOnUiThread {
                            result.error("write-failed", "The selected folder could not be written.", null)
                        }
                    }
                }
            }
            "delete" -> {
                val uri = call.argument<String>("uri")!!
                val path = call.argument<String>("path")!!
                fileReads.execute {
                    try {
                        val removed = delete(uri, path)
                        runOnUiThread { result.success(removed) }
                    } catch (_: Exception) {
                        runOnUiThread {
                            result.error("delete-failed", "The file could not be removed.", null)
                        }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun pick(
        action: String,
        requestCode: Int,
        result: MethodChannel.Result,
        keep: Boolean = true,
    ) {
        pendingPick?.success(null)
        pendingPick = result
        pendingKeep = keep

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
        val keep = isFolder || pendingKeep
        pendingKeep = true

        val picked = data?.data
        if (resultCode != RESULT_OK || picked == null) {
            result.success(null)
            return
        }

        // Without this the grant lasts only as long as this process, and
        // whatever was picked would have to be picked again on every
        // launch. A file is only ever read, so read is all it asks for.
        //
        // Not for a file picked for once (#410). Android keeps 128 lasting
        // grants up to version 10 and 512 after, and past that it drops the
        // oldest without a word: often the shared folder's, picked first.
        // A provider may also refuse to make a grant last; the pick then
        // works for this run instead of taking the app down.
        if (keep) {
            try {
                contentResolver.takePersistableUriPermission(
                    picked,
                    if (isFolder) {
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    } else {
                        Intent.FLAG_GRANT_READ_URI_PERMISSION
                    },
                )
            } catch (_: Exception) {
                // Reachable for this run, as an unkept pick is.
            }
        }

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

    /**
     * Gives back the lasting grant on one picked file, once nothing the app
     * remembers names it any more (#410); which that is, Dart knows. True
     * when there was one. Never a folder's: the shared folder's grant is
     * what the sync stands on, and only the person takes it away.
     */
    private fun release(uri: String): Boolean {
        val target = Uri.parse(uri)
        val segments = target.pathSegments
        if (segments.size >= 2 && segments[0] == "tree") return false
        var released = false
        for (permission in contentResolver.persistedUriPermissions) {
            if (permission.uri != target) continue
            var modes = 0
            if (permission.isReadPermission) modes = modes or Intent.FLAG_GRANT_READ_URI_PERMISSION
            if (permission.isWritePermission) modes = modes or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            if (modes == 0) continue
            contentResolver.releasePersistableUriPermission(target, modes)
            released = true
        }
        return released
    }

    // --- Ranged reads, for the offline map archive ----------------------

    /**
     * Opens [uri] for ranged reads under [token], and answers whether it
     * could be opened.
     *
     * Not on the main thread (#410): a cloud provider may fetch the whole
     * file before it hands out a descriptor, and for a backup in Nextcloud
     * or Drive that is long enough for "app not responding". The
     * descriptor is filed on the main thread, where [openFiles] lives, and
     * before the answer, so the first read finds it.
     */
    private fun openFile(uri: String, token: String?, result: MethodChannel.Result) {
        val key = token ?: uri
        closeFile(key)
        fileReads.execute {
            val descriptor = runCatching {
                contentResolver.openFileDescriptor(Uri.parse(uri), "r")
            }.getOrNull()
            runOnUiThread {
                when {
                    descriptor == null -> result.success(false)
                    isDestroyed -> {
                        runCatching { descriptor.close() }
                        result.success(false)
                    }
                    else -> {
                        closeFile(key)
                        openFiles[key] = descriptor
                        result.success(true)
                    }
                }
            }
        }
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

        rangeReads.execute {
            val outcome = runCatching {
                // A stream around this descriptor would close it after the
                // first read. Positional reads keep its lifetime with the
                // reader and do not change another request's file offset.
                val buffer = ByteArray(length)
                var received = 0
                while (received < length) {
                    val read = Os.pread(
                        descriptor.fileDescriptor, buffer, received,
                        length - received, offset + received,
                    )
                    if (read <= 0) break
                    received += read
                }
                buffer.copyOf(received)
            }
            runOnUiThread {
                outcome.fold(
                    onSuccess = { result.success(it) },
                    onFailure = { result.error("read-failed", it.message, null) },
                )
            }
        }
    }

    /**
     * Forgets the descriptor at once and closes it after the reads already
     * queued for it: closed under a running read, its number could go to
     * the next file opened, and the read would carry on in that one.
     */
    private fun closeFile(uri: String) {
        val descriptor = openFiles.remove(uri) ?: return
        try {
            rangeReads.execute { runCatching { descriptor.close() } }
        } catch (_: RejectedExecutionException) {
            runCatching { descriptor.close() }
        }
    }

    override fun onDestroy() {
        openFiles.values.forEach { runCatching { it.close() } }
        openFiles.clear()
        fileReads.shutdown()
        rangeReads.shutdown()
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
        // A folder the provider cannot list is not one to write to; that
        // is what DocumentFile answered here before (#410).
        return root.canWrite() && runCatching {
            resolveDirectory(root.uri, listOf("preppsuite", "devices"), create = true)
        }.getOrNull() != null
    }

    /**
     * The names of the files in a directory, in one query.
     *
     * `DocumentFile.listFiles()` and then `isFile` and `name` on each child
     * is two more queries per file; with the household's pictures in the
     * folder that was some six hundred binder calls every two minutes
     * (#376). The same children, asked for their name and type at once.
     */
    private fun list(uri: String, path: String): List<String> {
        val directory = directoryAt(uri, path, create = false) ?: return emptyList()
        return children(directory).filterValues { it.isFile }.keys.toList()
    }

    /** One entry of a directory in the tree. */
    private class Child(val uri: Uri, type: String?) {
        // What DocumentFile says: a folder has the folder type, a file
        // some other type, and an entry without one is neither.
        val isDirectory = type == DocumentsContract.Document.MIME_TYPE_DIR
        val isFile = !type.isNullOrEmpty() && !isDirectory
    }

    /**
     * The entries of [directory] by name, in one query.
     *
     * `DocumentFile.findFile` lists the directory and then asks each entry
     * for its name, one binder call apiece. Looking up every picture that
     * way cost a call per picture already in the folder, a run through N
     * pictures some N squared calls (#410). Here a lookup is one query per
     * directory on the way, with name, id and type at once. Of two entries
     * with one name the first counts, as with `findFile`.
     *
     * A provider that does not answer at all is an error rather than an
     * empty folder: taken for empty, a read would say a file is missing
     * (#312) and a write would put a second one beside it.
     */
    private fun children(directory: Uri): Map<String, Child> {
        val query = DocumentsContract.buildChildDocumentsUriUsingTree(
            directory,
            DocumentsContract.getDocumentId(directory),
        )
        val found = LinkedHashMap<String, Child>()
        val cursor = contentResolver.query(
            query,
            arrayOf(
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_MIME_TYPE,
            ),
            null,
            null,
            null,
        ) ?: throw java.io.IOException("The folder could not be listed.")
        cursor.use {
            while (it.moveToNext()) {
                val name = it.getString(0) ?: continue
                val id = it.getString(1) ?: continue
                if (name in found) continue
                found[name] = Child(
                    DocumentsContract.buildDocumentUriUsingTree(directory, id),
                    it.getString(2),
                )
            }
        }
        return found
    }

    /**
     * A new document in [directory], or null where the provider makes
     * none, as `DocumentFile.createFile` and `createDirectory` answer.
     */
    private fun createDocument(directory: Uri, type: String, name: String): Uri? = runCatching {
        DocumentsContract.createDocument(contentResolver, directory, type, name)
    }.getOrNull()

    private class ReadTooLarge : Exception()

    private fun read(uri: String, path: String, maxBytes: Int): String? {
        val segments = path.split('/')
        val directory = directoryAt(uri, segments.dropLast(1).joinToString("/"), create = false)
            ?: return null
        val file = children(directory)[segments.last()] ?: return null
        if (!file.isFile) return null

        val input = contentResolver.openInputStream(file.uri)
            ?: throw java.io.IOException("No stream for an existing file.")
        return input.use { stream ->
            val limit = maxBytes.coerceIn(0, 64 * 1024 * 1024)
            val bytes = java.io.ByteArrayOutputStream()
            val buffer = ByteArray(8192)
            while (true) {
                val count = stream.read(buffer, 0, minOf(buffer.size, limit - bytes.size() + 1))
                if (count < 0) break
                if (bytes.size() + count > limit) throw ReadTooLarge()
                bytes.write(buffer, 0, count)
            }
            bytes.toString(Charsets.UTF_8.name())
        }
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
            ?: throw java.io.IOException("No writable directory")
        val name = segments.last()
        val file = children(directory)[name]?.uri
            ?: createDocument(directory, "application/json", name)
            ?: throw java.io.IOException("No writable file")

        val stream = contentResolver.openOutputStream(file, "wt")
            ?: throw java.io.IOException("No output stream")
        stream.use {
            it.write(contents.toByteArray(Charsets.UTF_8))
            it.flush()
        }
    }

    /**
     * Removes one file inside the folder: a picture no row names any more
     * (#376). False when there was nothing to remove; the caller tries
     * again on a later run either way.
     */
    private fun delete(uri: String, path: String): Boolean {
        val segments = path.split('/')
        val name = segments.last()
        if (name.isEmpty() || name == "." || name == ".." || segments.contains("..")) return false
        val directory = directoryAt(uri, segments.dropLast(1).joinToString("/"), create = false)
            ?: return false
        val file = children(directory)[name] ?: return false
        return file.isFile && runCatching {
            DocumentsContract.deleteDocument(contentResolver, file.uri)
        }.getOrDefault(false)
    }

    private fun directoryAt(uri: String, path: String, create: Boolean): Uri? {
        // A handle that is not (or no longer) a document tree, such as one
        // restored from another platform, is simply not there.
        val root = try {
            DocumentFile.fromTreeUri(this, Uri.parse(uri))
        } catch (e: IllegalArgumentException) {
            null
        } ?: return null
        val segments = path.split('/').filter { it.isNotEmpty() }
        return resolveDirectory(root.uri, segments, create)
    }

    private fun resolveDirectory(
        root: Uri,
        segments: List<String>,
        create: Boolean,
    ): Uri? {
        var current = root
        for (segment in segments) {
            val existing = children(current)[segment]
            current = when {
                existing != null && existing.isDirectory -> existing.uri
                existing != null -> return null
                create ->
                    createDocument(current, DocumentsContract.Document.MIME_TYPE_DIR, segment)
                        ?: return null
                else -> return null
            }
        }
        return current
    }
}
