import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf_document/pdf_document.dart';
import 'package:pdf_graphics/pdf_graphics.dart';

import '../../../core/platform_storage.dart';
import '../../maps/application/map_archive_access.dart';
import 'personal_document_store.dart';

/// The largest personal document read at all, on [platform].
///
/// One number for the reader and the index, so that what can be opened
/// can also be found — they used to differ, and a document that could be
/// read end to end and never turned up in a search was the worse surprise.
///
/// Lower on a phone or a tablet. The file is read whole, because neither
/// the ZIP decoder nor the PDF parser works from a stream, so the limit is
/// also the peak allocation, before the text that comes out of it. A
/// desktop can afford 256 MB of that; a phone that the system ends for
/// using too much memory loses whatever else was open.
///
/// Decimal megabytes, so the message that names the limit says "128 MB"
/// rather than a binary figure nobody recognises.
int personalDocumentByteLimit([TargetPlatform? platform]) =>
    switch (platform ?? defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => 128 * 1000 * 1000,
      _ => 256 * 1000 * 1000,
    };

/// How much extracted text is kept per document, for the reader and the
/// index alike. Roughly two thousand printed pages.
const personalDocumentMaxCharacters = 4 * 1024 * 1024;

/// The document, or a part of it, is more than this device reads.
class PersonalDocumentTooLarge implements Exception {
  const PersonalDocumentTooLarge({required this.limit, this.bytes});

  /// The file's size, when that was what exceeded the limit. Null when it
  /// was something inside — an EPUB with too many entries, a chapter that
  /// inflates past its bound.
  final int? bytes;

  final int limit;

  @override
  String toString() => 'PersonalDocumentTooLarge(bytes: $bytes, limit: $limit)';
}

/// The reading was stopped by the person waiting for it.
class PersonalDocumentCancelled implements Exception {
  const PersonalDocumentCancelled();
}

/// How far a [PersonalDocumentTextJob] has got.
sealed class PersonalDocumentProgress {
  const PersonalDocumentProgress();
}

/// Bytes coming off the disk or out of the platform's storage.
class PersonalDocumentReading extends PersonalDocumentProgress {
  const PersonalDocumentReading(this.received, this.total);

  final int received;

  /// Null where the platform does not say in advance — an Android
  /// document behind a content URI.
  final int? total;
}

/// Text coming out of the file: chapters of an EPUB, pages of a PDF.
class PersonalDocumentExtracting extends PersonalDocumentProgress {
  const PersonalDocumentExtracting(this.done, this.total);

  final int done;
  final int total;
}

/// What came out of a document.
class PersonalDocumentText {
  const PersonalDocumentText({
    required this.paragraphs,
    required this.truncated,
  });

  /// In reading order, each with its whitespace collapsed. Kept apart
  /// rather than joined, because the reader lays them out one at a time:
  /// a single text of four million characters is laid out in one go, on
  /// the interface's own thread, and that is the freeze this exists to
  /// prevent.
  final List<String> paragraphs;

  /// The document had more than [personalDocumentMaxCharacters].
  final bool truncated;

  /// The whole text as one line, for the search index.
  String get searchText => paragraphs.join(' ');
}

/// Reads and extracts one personal document away from the interface.
///
/// The index used to do the extraction in an isolate and the reader on the
/// interface's own thread, from the same bytes, with the same parser: a
/// large or damaged EPUB froze the screen on opening. Both go through this
/// now. A file on disk is read inside the isolate as well, so its bytes
/// never pass through the interface's heap at all; an Android document can
/// only be read through the platform channel, so it is read here in chunks
/// and handed over without a copy.
///
/// [cancel] ends the isolate at once. Neither the ZIP decoder nor the PDF
/// parser can be interrupted from outside, so ending the isolate is the
/// only way to stop a parse that has started.
class PersonalDocumentTextJob {
  PersonalDocumentTextJob._(this.document, this.maxBytes);

  /// Starts reading [document]. [maxBytes] defaults to this device's
  /// [personalDocumentByteLimit].
  factory PersonalDocumentTextJob.start(
    PersonalDocument document, {
    int? maxBytes,
  }) {
    final job = PersonalDocumentTextJob._(
      document,
      maxBytes ?? personalDocumentByteLimit(),
    );
    unawaited(job._run());
    return job;
  }

  final PersonalDocument document;
  final int maxBytes;

  final _progress = StreamController<PersonalDocumentProgress>.broadcast();
  final _result = Completer<PersonalDocumentText>();
  Isolate? _isolate;
  ReceivePort? _port;
  var _cancelled = false;

  Stream<PersonalDocumentProgress> get progress => _progress.stream;

  /// Completes with the text, or with [PersonalDocumentTooLarge],
  /// [PersonalDocumentCancelled] or whatever the parser threw.
  Future<PersonalDocumentText> get result => _result.future;

  void cancel() {
    if (_cancelled || _result.isCompleted) return;
    _cancelled = true;
    _isolate?.kill(priority: Isolate.immediate);
    _finish(error: const PersonalDocumentCancelled());
  }

  Future<void> _run() async {
    try {
      var location = document.location;
      if (location.startsWith('bookmark://')) {
        location = await resolveStoragePath(location) ?? location;
      }
      if (_cancelled) return;

      TransferableTypedData? bytes;
      String? path;
      if (isNativeStorageHandle(location)) {
        bytes = TransferableTypedData.fromList([
          await readPersonalDocumentBytes(
            location,
            maxBytes: maxBytes,
            onProgress: (received) =>
                _emit(PersonalDocumentReading(received, null)),
            isCancelled: () => _cancelled,
          ),
        ]);
      } else {
        path = location;
      }
      if (_cancelled) return;

      final port = _port = ReceivePort();
      port.listen(_receive);
      _isolate = await Isolate.spawn(
        _extractInIsolate,
        _Request(
          reply: port.sendPort,
          extension: document.extension,
          path: path,
          bytes: bytes,
          maxBytes: maxBytes,
        ),
        errorsAreFatal: true,
        onError: port.sendPort,
        onExit: port.sendPort,
      );
      // Cancelled while the isolate was being spawned.
      if (_cancelled) _isolate?.kill(priority: Isolate.immediate);
    } on Object catch (error, stack) {
      _finish(error: error, stack: stack);
    }
  }

  void _receive(Object? message) {
    switch (message) {
      case PersonalDocumentProgress():
        _emit(message);
      case PersonalDocumentText():
        _finish(text: message);
      case _TooLarge(:final bytes):
        _finish(
          error: PersonalDocumentTooLarge(limit: maxBytes, bytes: bytes),
        );
      case [final String error, final String? stack]:
        // An uncaught error, in the shape `onError` reports it.
        _finish(
          error: StateError(error),
          stack: stack == null ? null : StackTrace.fromString(stack),
        );
      case null:
        // The isolate ended. Anything it had to say has arrived by now; if
        // nothing did, it was killed or crashed.
        _finish(error: const PersonalDocumentCancelled());
    }
  }

  void _emit(PersonalDocumentProgress progress) {
    if (!_progress.isClosed) _progress.add(progress);
  }

  void _finish({
    PersonalDocumentText? text,
    Object? error,
    StackTrace? stack,
  }) {
    if (!_result.isCompleted) {
      if (text != null) {
        _result.complete(text);
      } else {
        _result.completeError(error!, stack);
      }
    }
    _port?.close();
    unawaited(_progress.close());
  }
}

/// Reads one personal document without copying it into app storage.
///
/// The file picker deliberately keeps the original where the person chose
/// it. Android therefore gives us a content URI rather than a path, while
/// desktop platforms use ordinary files. Bounded, so a large or malformed
/// document cannot make anything allocate without a limit; the length of
/// an ordinary file is checked before a byte is read.
Future<Uint8List> readPersonalDocumentBytes(
  String location, {
  required int maxBytes,
  void Function(int received)? onProgress,
  bool Function()? isCancelled,
}) async {
  var path = location;
  if (path.startsWith('bookmark://')) {
    path = await resolveStoragePath(path) ?? path;
  }
  if (!isNativeStorageHandle(path)) {
    final file = File(path);
    final length = await file.length();
    if (length > maxBytes) {
      throw PersonalDocumentTooLarge(limit: maxBytes, bytes: length);
    }
    return file.readAsBytes();
  }

  final source = await NativeByteRangeSource.open(path);
  final builder = BytesBuilder(copy: false);
  const chunkSize = 1024 * 1024;
  try {
    for (var offset = 0; ; offset += chunkSize) {
      if (isCancelled?.call() ?? false) {
        throw const PersonalDocumentCancelled();
      }
      final chunk = await source.read(offset, chunkSize);
      if (builder.length + chunk.length > maxBytes) {
        throw PersonalDocumentTooLarge(limit: maxBytes);
      }
      builder.add(chunk);
      onProgress?.call(builder.length);
      if (chunk.length < chunkSize) return builder.takeBytes();
    }
  } finally {
    await source.close();
  }
}

/// Extracts [bytes] where the caller already is — for a test, or for
/// another isolate. The app goes through [PersonalDocumentTextJob].
@visibleForTesting
PersonalDocumentText extractPersonalDocumentText(
  String extension,
  Uint8List bytes, {
  int maxBytes = 256 * 1000 * 1000,
  void Function(PersonalDocumentProgress progress)? onProgress,
}) => _Extractor(maxBytes, onProgress).extract(extension, bytes);

class _Request {
  const _Request({
    required this.reply,
    required this.extension,
    required this.path,
    required this.bytes,
    required this.maxBytes,
  });

  final SendPort reply;
  final String extension;
  final String? path;
  final TransferableTypedData? bytes;
  final int maxBytes;
}

class _TooLarge {
  const _TooLarge(this.bytes);

  final int? bytes;
}

Future<void> _extractInIsolate(_Request request) async {
  final reply = request.reply;
  try {
    final Uint8List bytes;
    if (request.path case final path?) {
      bytes = await _readFile(path, request.maxBytes, reply);
    } else {
      bytes = request.bytes!.materialize().asUint8List();
    }
    final text = _Extractor(
      request.maxBytes,
      reply.send,
    ).extract(request.extension, bytes);
    // The last word, handed over rather than copied.
    Isolate.exit(reply, text);
  } on PersonalDocumentTooLarge catch (error) {
    reply.send(_TooLarge(error.bytes));
  }
}

/// A file read in chunks, so the reader can show how far it has got.
Future<Uint8List> _readFile(String path, int maxBytes, SendPort reply) async {
  final file = File(path);
  final length = await file.length();
  if (length > maxBytes) {
    throw PersonalDocumentTooLarge(limit: maxBytes, bytes: length);
  }
  final handle = await file.open();
  try {
    final bytes = Uint8List(length);
    const chunkSize = 4 * 1024 * 1024;
    var offset = 0;
    while (offset < length) {
      final end = (offset + chunkSize).clamp(0, length);
      final read = await handle.readInto(bytes, offset, end);
      if (read == 0) break;
      offset += read;
      reply.send(PersonalDocumentReading(offset, length));
    }
    return offset == length ? bytes : Uint8List.sublistView(bytes, 0, offset);
  } finally {
    await handle.close();
  }
}

class _Extractor {
  _Extractor(this.maxBytes, this.onProgress);

  final int maxBytes;
  final void Function(PersonalDocumentProgress progress)? onProgress;

  static const _maxEpubEntries = 4096;
  static const _maxEpubEntryBytes = 8 * 1024 * 1024;
  static const _maxEpubDecodedBytes = 16 * 1024 * 1024;

  final _paragraphs = <String>[];
  var _characters = 0;
  var _truncated = false;

  PersonalDocumentText extract(String extension, Uint8List bytes) {
    switch (extension) {
      case 'md' || 'markdown':
        onProgress?.call(const PersonalDocumentExtracting(0, 1));
        _addBlocks(utf8.decode(bytes, allowMalformed: true));
        onProgress?.call(const PersonalDocumentExtracting(1, 1));
      case 'epub':
        _extractEpub(bytes);
      case 'pdf':
        _extractPdf(bytes);
    }
    return PersonalDocumentText(
      paragraphs: List.unmodifiable(_paragraphs),
      truncated: _truncated,
    );
  }

  bool get _full => _truncated;

  void _extractEpub(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    if (archive.files.length > _maxEpubEntries) {
      throw PersonalDocumentTooLarge(limit: maxBytes);
    }
    final chapters = [
      for (final file in archive.files)
        if (file.isFile && _isChapter(file.name)) file,
    ];
    var decodedBytes = 0;
    for (final (index, file) in chapters.indexed) {
      onProgress?.call(PersonalDocumentExtracting(index, chapters.length));
      // The size in a ZIP header is only a claim, but rejecting a clearly
      // excessive one avoids starting an expensive inflate. The bounded
      // output below enforces the same limit against a forged header.
      if (file.size < 0 || file.size > _maxEpubEntryBytes) {
        throw PersonalDocumentTooLarge(limit: maxBytes);
      }
      final remaining = _maxEpubDecodedBytes - decodedBytes;
      if (remaining <= 0) throw PersonalDocumentTooLarge(limit: maxBytes);
      final output = _BoundedOutput(remaining, maxBytes);
      file.decompress(output);
      final content = output.getBytes();
      decodedBytes += content.length;
      _addBlocks(_blocksOf(utf8.decode(content, allowMalformed: true)));
      if (_full) break;
    }
    onProgress?.call(
      PersonalDocumentExtracting(chapters.length, chapters.length),
    );
  }

  static bool _isChapter(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.xhtml') ||
        lower.endsWith('.html') ||
        lower.endsWith('.htm');
  }

  void _extractPdf(Uint8List bytes) {
    final document = PdfDocument.open(bytes);
    final pages = document.pageCount;
    for (var page = 0; page < pages; page++) {
      onProgress?.call(PersonalDocumentExtracting(page, pages));
      _addBlocks(PdfTextExtractor.extract(document, page).text);
      if (_full) break;
    }
    onProgress?.call(PersonalDocumentExtracting(pages, pages));
  }

  /// Splits [text] at blank lines and keeps each piece as a paragraph.
  void _addBlocks(String text) {
    for (final block in text.split(_blankLine)) {
      if (_full) return;
      final paragraph = _stripMarkup(
        block,
      ).replaceAll(_whitespace, ' ').trim();
      if (paragraph.isEmpty) continue;
      final room = personalDocumentMaxCharacters - _characters;
      if (paragraph.length >= room) {
        if (room > 0) _paragraphs.add(paragraph.substring(0, room));
        _characters = personalDocumentMaxCharacters;
        _truncated = true;
        return;
      }
      _paragraphs.add(paragraph);
      _characters += paragraph.length + 1;
    }
  }

  static final _blankLine = RegExp(r'\n\s*\n');
  static final _whitespace = RegExp(r'\s+');
  static final _blockEnd = RegExp(
    r'</(p|div|h[1-6]|li|tr|blockquote|section|article|pre)\s*>|<br\s*/?>',
    caseSensitive: false,
  );

  /// Turns the end of every block element into a blank line, so a chapter
  /// keeps its paragraphs once the markup is gone.
  static String _blocksOf(String html) => html
      .replaceAll(
        RegExp(r'<(script|style)\b[^>]*>[\s\S]*?</\1>', caseSensitive: false),
        '',
      )
      .replaceAll(_blockEnd, '\n\n');

  static String _stripMarkup(String value) => value
      .replaceAll(
        RegExp(r'<script\b[^>]*>[\s\S]*?</script>', caseSensitive: false),
        '',
      )
      .replaceAll(
        RegExp(r'<style\b[^>]*>[\s\S]*?</style>', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}

/// Archive's normal memory output grows without a ceiling. EPUBs are ZIP
/// files supplied by other people, so every entry is capped while it is
/// inflated.
class _BoundedOutput extends OutputMemoryStream {
  _BoundedOutput(this._limit, this._documentLimit) : super(size: 32 * 1024);

  final int _limit;
  final int _documentLimit;

  void _reserve(int count) {
    if (count < 0 || length + count > _limit) {
      throw PersonalDocumentTooLarge(limit: _documentLimit);
    }
  }

  @override
  void writeByte(int value) {
    _reserve(1);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _reserve(length ?? bytes.length);
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    _reserve(stream.length);
    super.writeStream(stream);
  }
}
