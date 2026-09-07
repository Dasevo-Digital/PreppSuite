import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'zim_archive.dart' show ZimBlobLocation;

/// Searches the full-text index a ZIM archive already carries.
///
/// The archive ships a Xapian database inside it — the same one Kiwix
/// searches — and Xapian can open a single-file database from a
/// descriptor at an offset. So this reads it where it lies: no index of
/// our own to build, no gigabytes to write, and the archive's own
/// stemmer, which is what finds "Notvorrat" for "Notvorräte".
///
/// Not every archive has one. `KnowledgeIndexer` stays for those.
///
/// Calls block. That is on purpose at this layer — it is a binding, not a
/// service — and the caller is expected to keep it off the UI isolate.
/// One index is one Xapian database, which is not safe to use from two
/// threads at once.
class XapianIndex {
  XapianIndex._(this._handle);

  final Pointer<_ZxSearcher> _handle;
  bool _closed = false;

  /// Opens the index inside the archive at [path].
  ///
  /// [location] is where `ZimArchive.directAccessInfo` said the index
  /// blob starts.
  static XapianIndex openFile(String path, ZimBlobLocation location) {
    final native = path.toNativeUtf8();
    try {
      return XapianIndex._(_bindings.openPath(native, location.offset));
    } finally {
      calloc.free(native);
    }
  }

  /// Opens the index through an already-open file descriptor.
  ///
  /// The way in on Android, where the archive is a `content://` document
  /// with no path to open. The descriptor is taken over and closed by
  /// Xapian — including when opening fails — so it must be one of its
  /// own, not the one the rest of the reader is using.
  static XapianIndex openDescriptor(int fd, ZimBlobLocation location) =>
      XapianIndex._(_bindings.openFd(fd, location.offset));

  /// Why the index could not be opened, or null when it is usable.
  String? get problem {
    final message = _bindings.error(_handle).toDartString();
    return message.isEmpty ? null : message;
  }

  /// The language the index was built for, or null when it names none —
  /// in which case queries are matched unstemmed.
  String? get language {
    final tag = _bindings.language(_handle).toDartString();
    return tag.isEmpty ? null : tag;
  }

  int get documentCount => _bindings.documentCount(_handle);

  /// Roughly how many articles match, from the last [search].
  int get estimatedMatches => _bindings.estimatedMatches(_handle);

  List<XapianHit> search(String query, {int offset = 0, int limit = 25}) {
    if (query.trim().isEmpty) return const [];

    final native = query.toNativeUtf8();
    try {
      final count = _bindings.search(_handle, native, offset, limit);
      if (count < 0) {
        throw XapianException(problem ?? 'the query could not be run');
      }

      final fullPaths = _bindings.hasFullPaths(_handle) == 1;
      return [
        for (var at = 0; at < count; at++) _hitAt(at, fullPaths: fullPaths),
      ];
    } finally {
      calloc.free(native);
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _bindings.close(_handle);
  }

  XapianHit _hitAt(int index, {required bool fullPaths}) {
    final path = _bindings.resultPath(_handle, index).toDartString();

    // Current archives store the entry's whole path, namespace and all;
    // older ones store a bare URL that was always in the article
    // namespace. The shape is checked as well as the flag, because a
    // stored path is what the lookup afterwards depends on.
    final prefixed = fullPaths && path.length > 2 && path[1] == '/';
    return XapianHit(
      namespace: prefixed ? path[0] : 'A',
      url: prefixed ? path.substring(2) : path,
      snippet: _bindings.resultSnippet(_handle, index).toDartString(),
    );
  }
}

/// One article the index matched.
class XapianHit {
  const XapianHit({
    required this.namespace,
    required this.url,
    required this.snippet,
  });

  /// Together with [url], what `ZimArchive.findByUrl` takes.
  ///
  /// There is no title here on purpose: the slot the index calls "title"
  /// holds a lowercased sort key. The entry this resolves to carries the
  /// real one.
  final String namespace;
  final String url;

  /// The passage the match was found in, when the archive stored one.
  ///
  /// Usually empty: current Kiwix archives keep only a sort title and a
  /// word count, so a preview has to come from the article itself.
  final String snippet;
}

class XapianException implements Exception {
  const XapianException(this.message);

  final String message;

  @override
  String toString() => 'XapianException: $message';
}

/// Whether the native library is present at all.
///
/// It is not on every platform, and a missing one is an ordinary state
/// rather than a failure — the app falls back to its own index.
bool get xapianAvailable {
  try {
    _bindings;
    return true;
  } on Object {
    return false;
  }
}

// --- The binding ------------------------------------------------------

final class _ZxSearcher extends Opaque {}

_Bindings? _cached;

_Bindings get _bindings => _cached ??= _Bindings(_openLibrary());

/// Looks in the four places the library can be, in the order it is most
/// likely to be found: told to us, bundled with the app, on the loader's
/// own search path, or sitting in the build directory of a working copy.
DynamicLibrary _openLibrary() {
  final name = Platform.isWindows
      ? 'zim_xapian.dll'
      : Platform.isMacOS || Platform.isIOS
      ? 'libzim_xapian.dylib'
      : 'libzim_xapian.so';

  final candidates = [
    ?Platform.environment['ZIM_XAPIAN_LIBRARY'],
    ?_bundled(name),
    name,
    'native/zim_xapian/build/$name',
  ];

  for (final candidate in candidates) {
    try {
      return DynamicLibrary.open(candidate);
    } on ArgumentError {
      continue;
    }
  }
  throw XapianException('$name was not found');
}

/// Where a shipped copy lies inside the app bundle.
///
/// By full path rather than by name: the loader resolves a bare name
/// against its own search paths, and `@rpath` is not one of them for
/// `dlopen`. Null where there is no bundle to look in.
String? _bundled(String name) {
  if (!Platform.isMacOS) return null;
  final contents = File(Platform.resolvedExecutable).parent.parent;
  return '${contents.path}/Frameworks/$name';
}

/// Hand-written rather than generated: eleven functions, no structs and
/// no callbacks, against a header this repository owns.
class _Bindings {
  _Bindings(DynamicLibrary library)
    : openPath = library
          .lookup<
            NativeFunction<Pointer<_ZxSearcher> Function(Pointer<Utf8>, Int64)>
          >(
            'zx_open_path',
          )
          .asFunction(),
      openFd = library
          .lookup<NativeFunction<Pointer<_ZxSearcher> Function(Int32, Int64)>>(
            'zx_open_fd',
          )
          .asFunction(),
      close = library
          .lookup<NativeFunction<Void Function(Pointer<_ZxSearcher>)>>(
            'zx_close',
          )
          .asFunction(),
      error = library
          .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<_ZxSearcher>)>>(
            'zx_error',
          )
          .asFunction(),
      language = library
          .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<_ZxSearcher>)>>(
            'zx_language',
          )
          .asFunction(),
      hasFullPaths = library
          .lookup<NativeFunction<Int32 Function(Pointer<_ZxSearcher>)>>(
            'zx_has_full_paths',
          )
          .asFunction(),
      documentCount = library
          .lookup<NativeFunction<Int32 Function(Pointer<_ZxSearcher>)>>(
            'zx_document_count',
          )
          .asFunction(),
      search = library
          .lookup<
            NativeFunction<
              Int32 Function(Pointer<_ZxSearcher>, Pointer<Utf8>, Int32, Int32)
            >
          >('zx_search')
          .asFunction(),
      estimatedMatches = library
          .lookup<NativeFunction<Int32 Function(Pointer<_ZxSearcher>)>>(
            'zx_estimated_matches',
          )
          .asFunction(),
      resultPath = library
          .lookup<
            NativeFunction<Pointer<Utf8> Function(Pointer<_ZxSearcher>, Int32)>
          >('zx_result_path')
          .asFunction(),
      resultSnippet = library
          .lookup<
            NativeFunction<Pointer<Utf8> Function(Pointer<_ZxSearcher>, Int32)>
          >('zx_result_snippet')
          .asFunction();

  final Pointer<_ZxSearcher> Function(Pointer<Utf8>, int) openPath;
  final Pointer<_ZxSearcher> Function(int, int) openFd;
  final void Function(Pointer<_ZxSearcher>) close;
  final Pointer<Utf8> Function(Pointer<_ZxSearcher>) error;
  final Pointer<Utf8> Function(Pointer<_ZxSearcher>) language;
  final int Function(Pointer<_ZxSearcher>) hasFullPaths;
  final int Function(Pointer<_ZxSearcher>) documentCount;
  final int Function(Pointer<_ZxSearcher>, Pointer<Utf8>, int, int) search;
  final int Function(Pointer<_ZxSearcher>) estimatedMatches;
  final Pointer<Utf8> Function(Pointer<_ZxSearcher>, int) resultPath;
  final Pointer<Utf8> Function(Pointer<_ZxSearcher>, int) resultSnippet;
}
