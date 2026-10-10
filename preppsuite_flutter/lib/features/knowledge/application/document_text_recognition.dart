/// A scanned PDF read page by page through the text recognizer (#66).
///
/// Pages are drawn by PDFium -- the renderer the reader already uses --
/// at 150 dpi, which the measurement found to read as well as 300 at a
/// fraction of the memory (`docs/texterkennung-messung.md`). One page at a
/// time: a page image is the largest thing in memory, and a manual of two
/// hundred large scans held all at once is how the measurement's first
/// attempt reached over two gigabytes.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

import '../../../core/platform_storage.dart';
import 'personal_document_store.dart';
import 'personal_document_text.dart';
import 'text_recognition.dart';

/// Pages of a document as images.
abstract interface class PageSource {
  int get pageCount;

  Future<PageImage> render(int page);

  Future<void> close();
}

/// What the measurement settled on: more than this reads no better.
const recognitionDpi = 150;

/// The longest side of a page image, whatever its paper size. A plan or
/// a poster at 150 dpi would otherwise be a page of a hundred megabytes.
const maxRecognitionPixels = 4000;

class PdfPageSource implements PageSource {
  PdfPageSource._(this._document);

  final PdfDocument _document;

  /// Opens [document] where it lies: a path, a bookmark resolved to one,
  /// or -- an Android document URI -- its bytes, read within the device's
  /// limit like everything else the library reads.
  static Future<PdfPageSource> open(PersonalDocument document) async {
    await pdfrxFlutterInitialize();
    var location = document.location;
    if (location.startsWith('bookmark://')) {
      location = await resolveStoragePath(location) ?? location;
    }
    if (!isNativeStorageHandle(location)) {
      return PdfPageSource._(await PdfDocument.openFile(location));
    }
    final bytes = await readPersonalDocumentBytes(
      location,
      maxBytes: personalDocumentByteLimit(),
    );
    return PdfPageSource._(
      await PdfDocument.openData(bytes, sourceName: document.label),
    );
  }

  @override
  int get pageCount => _document.pages.length;

  @override
  Future<PageImage> render(int page) async {
    final pdfPage = _document.pages[page];
    // Points are 1/72 inch.
    var width = pdfPage.width * recognitionDpi / 72;
    var height = pdfPage.height * recognitionDpi / 72;
    final longest = math.max(width, height);
    if (longest > maxRecognitionPixels) {
      final scale = maxRecognitionPixels / longest;
      width *= scale;
      height *= scale;
    }
    final image = await pdfPage.render(
      fullWidth: width,
      fullHeight: height,
      // White, not transparent: a scan's background is paper, and an
      // engine reading black text off transparent black reads nothing.
      backgroundColor: 0xFFFFFFFF,
    );
    if (image == null) throw StateError('page $page did not render');
    try {
      return PageImage(
        bgra: Uint8List.fromList(image.pixels),
        width: image.width,
        height: image.height,
      );
    } finally {
      image.dispose();
    }
  }

  @override
  Future<void> close() => _document.dispose();
}

/// The text of every page of [source], as paragraphs for the index and
/// the reader, at most [maxCharacters].
///
/// [onProgress] hears each page as it is done; [isCancelled] is asked
/// between pages, which is the only point a recognition can be stopped.
/// A page that will not render or read is skipped rather than ending the
/// run: one bad page of a two-hundred-page scan should not cost the rest.
Future<PersonalDocumentText> recognizeDocument({
  required PageSource source,
  required TextRecognizer recognizer,
  int? maxCharacters,
  void Function(int done, int total)? onProgress,
  bool Function()? isCancelled,
}) async {
  final limit = maxCharacters ?? personalDocumentCharacterLimit();
  final paragraphs = <String>[];
  var characters = 0;
  var truncated = false;
  final total = source.pageCount;

  pages:
  for (var page = 0; page < total; page++) {
    if (isCancelled?.call() ?? false) throw const PersonalDocumentCancelled();
    onProgress?.call(page, total);
    final String text;
    try {
      text = await recognizer.recognize(await source.render(page));
    } on PersonalDocumentCancelled {
      rethrow;
    } on Object {
      continue;
    }
    for (final block in text.split(RegExp(r'\n\s*\n'))) {
      final paragraph = block.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (paragraph.isEmpty) continue;
      final room = limit - characters;
      if (paragraph.length >= room) {
        if (room > 0) paragraphs.add(paragraph.substring(0, room));
        truncated = true;
        break pages;
      }
      paragraphs.add(paragraph);
      characters += paragraph.length + 1;
    }
  }
  onProgress?.call(total, total);
  return PersonalDocumentText(
    paragraphs: List.unmodifiable(paragraphs),
    truncated: truncated,
  );
}
