import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:preppsuite_flutter/features/knowledge/application/tesseract_data.dart';
import 'package:preppsuite_flutter/features/phrasebook/application/phrasebook.dart';

/// Serves one body for every request, the whole file each time.
class _Server extends http.BaseClient {
  _Server(this.body);

  final List<int> body;
  final requested = <Uri>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requested.add(request.url);
    return http.StreamedResponse(
      Stream.value(body),
      200,
      contentLength: body.length,
    );
  }
}

Future<String> _sha(List<int> bytes) async {
  final hash = await Sha256().hash(bytes);
  return [
    for (final b in hash.bytes) b.toRadixString(16).padLeft(2, '0'),
  ].join();
}

/// The text recognition data "Text aus Foto" fetches on Android (#205).
void main() {
  late Directory folder;
  setUp(() => folder = Directory.systemTemp.createTempSync('tessdata'));
  tearDown(() => folder.deleteSync(recursive: true));

  final body = utf8.encode('a model, as far as this test is concerned');

  DownloadedTesseractData data(http.Client client) =>
      DownloadedTesseractData(folder: () async => folder, httpClient: client);

  test('fetched data is checked, in place under its name, and found', () async {
    final server = _Server(body);
    final language = TesseractLanguage('rus', body.length, await _sha(body));

    final progress = await data(server).install(language).toList();

    expect(progress.last, body.length);
    expect(
      server.requested.single.toString(),
      endsWith('/4.1.0/rus.traineddata'),
    );
    expect(File('${folder.path}/rus.traineddata').readAsBytesSync(), body);
    expect(await data(server).has(language), isTrue);

    await data(server).remove(language);
    expect(await data(server).has(language), isFalse);
  });

  test('data that does not match its checksum is not kept', () async {
    final language = TesseractLanguage('ukr', body.length, '0' * 64);

    await expectLater(
      data(_Server(body)).install(language).drain<void>(),
      throwsA(isA<TesseractDataException>()),
    );
    expect(File('${folder.path}/ukr.traineddata').existsSync(), isFalse);
    expect(await data(_Server(body)).has(language), isFalse);
  });

  test('data already in place is not fetched again', () async {
    final language = TesseractLanguage('ara', body.length, await _sha(body));
    File('${folder.path}/ara.traineddata').writeAsBytesSync(body);
    final server = _Server(body);

    await data(server).install(language).drain<void>();

    expect(server.requested, isEmpty);
  });

  test('every language beyond German and English has pinned data, and '
      'BCP-47 tags turn into Tesseract names', () {
    expect(tesseractLanguages.keys, isNot(contains(PhraseLanguage.de)));
    expect(tesseractLanguages.keys, isNot(contains(PhraseLanguage.en)));
    expect(
      tesseractLanguages.length,
      PhraseLanguage.values.length - 2,
    );
    for (final language in tesseractLanguages.values) {
      expect(language.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(language.size, greaterThan(100000));
    }
    expect(tesseractLanguageString(['ru-RU', 'en-US']), 'rus+eng');
    expect(tesseractLanguageString(['de-DE', 'en-US']), 'deu+eng');
    expect(
      tesseractLanguages[PhraseLanguage.fa]!.linuxPackage,
      'tesseract-ocr-fas',
    );
  });
}
