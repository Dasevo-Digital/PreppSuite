import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:preppsuite_flutter/features/phrasebook/application/phrasebook.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_catalogue.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_store.dart';

/// Serves fixed bytes per URL, the whole file every time.
class _Files extends http.BaseClient {
  _Files(this.bodies);

  final Map<String, List<int>> bodies;
  final requested = <String>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requested.add(request.url.toString());
    final body = bodies[request.url.toString()];
    if (body == null) return http.StreamedResponse(const Stream.empty(), 404);
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

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('translator'));
  tearDown(() => root.deleteSync(recursive: true));

  const direction = TranslatorDirection(PhraseLanguage.de, PhraseLanguage.en);
  final bodies = {
    'https://cdn.test/model': utf8.encode('model bytes'),
    'https://cdn.test/lex': utf8.encode('shortlist bytes'),
    'https://cdn.test/vocab': utf8.encode('vocabulary bytes'),
  };

  Future<TranslatorPack> pack({String? badModelHash}) async => TranslatorPack(
    direction: direction,
    version: '2.0',
    files: [
      for (final kind in TranslatorFileKind.values)
        TranslatorFile(
          kind: kind,
          name: '${kind.name}.deen.bin',
          size: bodies['https://cdn.test/${kind.name}']!.length,
          sha256: kind == TranslatorFileKind.model && badModelHash != null
              ? badModelHash
              : await _sha(bodies['https://cdn.test/${kind.name}']!),
          url: Uri.parse('https://cdn.test/${kind.name}'),
        ),
    ],
  );

  test('a pack is installed, checked, and found again', () async {
    final store = TranslatorStore(root: root, httpClient: _Files(bodies));
    final progress = await store.install(await pack()).toList();

    expect(progress.last.fraction, 1.0);
    final found = await store.find(direction);
    expect(found, isNotNull);
    expect(found!.version, '2.0');
    expect(File(found.modelPath).readAsStringSync(), 'model bytes');
    expect(await store.installed(), hasLength(1));
  });

  test('a file that does not match its checksum is thrown away', () async {
    final store = TranslatorStore(root: root, httpClient: _Files(bodies));
    await expectLater(
      store.install(await pack(badModelHash: '0' * 64)).drain<void>(),
      throwsA(isA<TranslatorStoreException>()),
    );
    // No manifest, so not a pack -- and no file under the model's name.
    expect(await store.find(direction), isNull);
    expect(File('${root.path}/deen/model.deen.bin').existsSync(), isFalse);
  });

  test('installing again fetches only what is missing', () async {
    final client = _Files(bodies);
    final store = TranslatorStore(root: root, httpClient: client);
    await store.install(await pack()).drain<void>();
    File('${root.path}/deen/lex.deen.bin').deleteSync();
    client.requested.clear();

    await store.install(await pack()).drain<void>();
    expect(client.requested, ['https://cdn.test/lex']);
  });

  test('a folder without its manifest is not a pack', () async {
    Directory('${root.path}/deen').createSync();
    File('${root.path}/deen/model.deen.bin').writeAsStringSync('x');
    expect(await TranslatorStore(root: root).installed(), isEmpty);
  });

  test('removing takes the whole direction away', () async {
    final store = TranslatorStore(root: root, httpClient: _Files(bodies));
    await store.install(await pack()).drain<void>();
    await store.remove(direction);
    expect(await store.find(direction), isNull);
    expect(Directory('${root.path}/deen').existsSync(), isFalse);
  });
}
