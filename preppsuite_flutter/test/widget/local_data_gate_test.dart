import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:preppsuite_flutter/core/local_data_gate.dart';
import 'package:preppsuite_flutter/core/local_database_encryption.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

class _MemoryKeyStorage implements LocalDatabaseKeyStorage {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

Widget _app(LocalDatabaseEncryption encryption) => MaterialApp(
  locale: const Locale('de'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: LocalDataGate(
    encryption: encryption,
    child: const Scaffold(body: Text('Haushalt')),
  ),
);

// Everything that touches the filesystem happens in `setUp`. Real
// asynchronous I/O started inside a `testWidgets` body runs in the
// binding's fake-async zone and simply never completes -- the same trap
// this project hit with the household database.
void main() {
  late Directory directory;
  late _MemoryKeyStorage storage;
  late LocalDatabaseEncryption readable;
  LocalDatabaseEncryption? lockedOut;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('preppsuite-gate-');
    storage = _MemoryKeyStorage();

    readable = LocalDatabaseEncryption(storage: storage);
    await readable.initialize(directory: directory);

    if (!LocalDatabaseEncryption.cipherAvailable) return;

    // An installation holding a database whose key it no longer has.
    final locked = await Directory.systemTemp.createTemp('preppsuite-locked-');
    final random = Random.secure();
    final key = base64UrlEncode(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    final database = sqlite3.open(
      '${locked.path}${Platform.pathSeparator}preppsuite.sqlite',
    );
    database
      ..execute("PRAGMA cipher = 'aes256cbc'")
      ..execute("PRAGMA key = '$key'")
      ..execute('CREATE TABLE household (name TEXT)')
      ..close();

    final lockedStorage = _MemoryKeyStorage()
      ..values['preppsuite.localDatabaseEncryption.mode.v1'] = 'encrypted';
    final encryption = LocalDatabaseEncryption(storage: lockedStorage);
    await encryption.initialize(directory: locked);
    expect(encryption.mode, LocalDatabaseEncryptionMode.recoveryRequired);
    lockedOut = encryption;
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  testWidgets('lets the app through when the data can be opened', (
    tester,
  ) async {
    await tester.pumpWidget(_app(readable));

    expect(find.text('Haushalt'), findsOneWidget);
  });

  testWidgets(
    'explains a lost key instead of failing somewhere later',
    (
      tester,
    ) async {
      await tester.pumpWidget(_app(lockedOut!));

      expect(find.text('Haushalt'), findsNothing);
      expect(find.text('Lokale Daten gesperrt'), findsOneWidget);
      expect(find.text('Erneut versuchen'), findsOneWidget);
      expect(find.text('Neu einrichten'), findsOneWidget);
    },
    skip: !LocalDatabaseEncryption.cipherAvailable,
  );

  testWidgets(
    'says what setting up again will and will not do',
    (
      tester,
    ) async {
      await tester.pumpWidget(_app(lockedOut!));
      await tester.tap(find.text('Neu einrichten'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('nicht gelöscht, sondern umbenannt'),
        findsOneWidget,
      );
    },
    skip: !LocalDatabaseEncryption.cipherAvailable,
  );
}
