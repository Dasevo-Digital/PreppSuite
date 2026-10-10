import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/document_text_recognition.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_index.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';
import 'package:preppsuite_flutter/features/knowledge/application/text_recognition.dart';

/// Reading a scanned document page by page (#66). The engines are the
/// systems'; what is held here is everything around them, against a
/// recogniser that answers what it is told to.
class _Pages implements PageSource {
  _Pages(this.count);

  final int count;
  final rendered = <int>[];
  var closed = false;

  @override
  int get pageCount => count;

  @override
  Future<PageImage> render(int page) async {
    rendered.add(page);
    if (page == 1) throw StateError('a damaged page');
    return PageImage(bgra: Uint8List(4), width: 1, height: 1);
  }

  @override
  Future<void> close() async => closed = true;
}

class _Reader implements TextRecognizer {
  _Reader(this.pages);

  final List<String> pages;
  var read = 0;

  @override
  Future<TextRecognitionSupport> support() async =>
      TextRecognitionSupport.available;

  @override
  Future<String> recognize(PageImage page) async => pages[read++];
}

void main() {
  test('every page is read in order, and a damaged one is skipped', () async {
    final pages = _Pages(3);
    final text = await recognizeDocument(
      source: pages,
      recognizer: _Reader([
        'Für den Notfall\nvorgesorgt\n\nVorräte für zehn Tage',
        'Wasser: 2 Liter',
      ]),
    );

    expect(pages.rendered, [0, 1, 2]);
    expect(text.paragraphs, [
      'Für den Notfall vorgesorgt',
      'Vorräte für zehn Tage',
      'Wasser: 2 Liter',
    ]);
    expect(text.truncated, isFalse);
  });

  test('stops at the character limit and says so', () async {
    final text = await recognizeDocument(
      source: _Pages(1),
      recognizer: _Reader(['${'x' * 50}\n\n${'y' * 50}']),
      maxCharacters: 60,
    );

    expect(text.truncated, isTrue);
    expect(
      text.paragraphs.fold<int>(0, (sum, p) => sum + p.length),
      lessThanOrEqualTo(60),
    );
  });

  test('a cancel between pages ends it without a result', () async {
    var asked = 0;
    await expectLater(
      recognizeDocument(
        source: _Pages(5),
        recognizer: _Reader(['a', 'b', 'c', 'd', 'e']),
        isCancelled: () => ++asked > 2,
      ),
      throwsA(isA<PersonalDocumentCancelled>()),
    );
  });

  test('says how far it got, page by page', () async {
    final seen = <(int, int)>[];
    await recognizeDocument(
      source: _Pages(3),
      recognizer: _Reader(['a', 'b']),
      onProgress: (done, total) => seen.add((done, total)),
    );

    expect(seen, [(0, 3), (1, 3), (2, 3), (3, 3)]);
  });

  test('what was recognised is found by the search', () async {
    final index = PersonalDocumentIndex.forTesting(NativeDatabase.memory());
    addTearDown(index.close);
    final document = PersonalDocument(
      id: 'scan',
      location: '/Dokumente/Broschuere.pdf',
      label: 'Broschuere.pdf',
      addedAt: DateTime.utc(2026),
    );

    final result = await PersonalDocumentIndexer(index: index).indexRecognized(
      document,
      const PersonalDocumentText(
        paragraphs: ['Vorräte für zehn Tage'],
        truncated: false,
      ),
    );

    expect(result.status, PersonalDocumentIndexStatus.ready);
    expect(await index.search('Vorräte'), isNotEmpty);
  });

  test('a recognised document says so, and keeps saying it', () {
    final document = PersonalDocument(
      id: 'scan',
      location: '/Dokumente/Broschuere.pdf',
      label: 'Broschuere.pdf',
      addedAt: DateTime.utc(2026),
      indexStatus: 'ready',
      recognized: true,
    );
    final back = PersonalDocument.fromJson(document.toJson())!;

    expect(back.recognized, isTrue);
    expect(
      PersonalDocument.fromJson(
        {
          ...document.toJson(),
        }..remove('recognized'),
      )!.recognized,
      isFalse,
    );
  });

  test('Tesseract gets grey pixels with a PGM header', () {
    // Pure red, green and blue: the usual luminance weights.
    final pgm = greyPgm(
      PageImage(
        bgra: Uint8List.fromList([
          0,
          0,
          255,
          255,
          0,
          255,
          0,
          255,
          255,
          0,
          0,
          255,
        ]),
        width: 3,
        height: 1,
      ),
    );

    expect(String.fromCharCodes(pgm.sublist(0, 11)), 'P5\n3 1\n255\n');
    expect(pgm.sublist(11), [76, 149, 29]);
  });
}
