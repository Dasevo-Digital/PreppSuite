package com.example.preppsuite_flutter

import android.content.Intent
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Gives the shared-folder sync a way to reach a folder the user picked.
 *
 * Android has not let an app open an arbitrary path since scoped storage:
 * the folder picker hands back a `content://` tree that only the Storage
 * Access Framework can read, and `dart:io` cannot touch it at all. So the
 * six things [SyncFolder] needs — probe, list, read, write, twice over —
 * are done here instead, against the same tree.
 *
 * The permission is taken as *persistable*, which is the part that makes
 * this worth doing: it survives a restart, so the user picks their
 * Nextcloud folder once rather than every launch.
 */
class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "preppsuite/shared_folder_saf"
        const val PICK_FOLDER_REQUEST = 8451
    }

    /** Set while the folder picker is open; there is only ever one. */
    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pick" -> pickFolder(result)
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

    private fun pickFolder(result: MethodChannel.Result) {
        pendingPick?.success(null)
        pendingPick = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
        )
        startActivityForResult(intent, PICK_FOLDER_REQUEST)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_FOLDER_REQUEST) return

        val result = pendingPick ?: return
        pendingPick = null

        val tree = data?.data
        if (resultCode != RESULT_OK || tree == null) {
            result.success(null)
            return
        }

        // Without this the grant lasts only as long as this process, and
        // the folder would have to be picked again on every launch.
        contentResolver.takePersistableUriPermission(
            tree,
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
        )

        result.success(
            mapOf(
                "uri" to tree.toString(),
                "label" to (DocumentFile.fromTreeUri(this, tree)?.name
                    ?: tree.lastPathSegment.orEmpty()),
            ),
        )
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
        val root = DocumentFile.fromTreeUri(this, Uri.parse(uri)) ?: return null
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
