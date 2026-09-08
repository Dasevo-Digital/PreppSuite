import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show DriftWrappedException;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/error_text.dart';
import 'package:preppsuite_flutter/features/downloads/application/archive_downloader.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_archive.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

/// What the user is told when something fails.
///
/// The point is not the wording but that the technical text stops
/// reaching the screen. Sixteen places used to print `error.toString()`,
/// which in an app that gets opened when something has already gone wrong
/// is the worst moment for "SqliteException(11)".
void main() {
  late AppLocalizations de;
  late AppLocalizations en;

  setUpAll(() async {
    de = await AppLocalizations.delegate.load(const Locale('de'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('a failure with a name gets a sentence, not a type', () {
    final cases = <Object, String Function(AppLocalizations)>{
      const SocketException('failed host lookup'): (l) => l.errorNoConnection,
      TimeoutException('too slow'): (l) => l.errorNoConnection,
      const PmTilesException('bad magic'): (l) => l.errorArchiveUnreadable,
      const ZimException('bad header'): (l) => l.errorArchiveUnreadable,
      const FileSystemException('no such file'): (l) => l.errorFileUnreadable,
      const DownloadException('got 3 of 9 bytes'): (l) => l.errorDownloadFailed,
      DriftWrappedException(
        message: 'insert',
        cause: 'disk image is malformed',
        trace: StackTrace.empty,
      ): (l) =>
          l.errorDatabase,
      PlatformException(code: 'denied'): (l) => l.errorPlatformRefused,
    };

    cases.forEach((error, expected) {
      expect(describeError(de, error), expected(de), reason: '$error');
      expect(describeError(en, error), expected(en), reason: '$error');
    });
  });

  test('nothing named keeps the technical text', () {
    // Deliberately not softened away: an unknown failure with no detail
    // left is one nobody can report and nobody can look up.
    final described = describeError(de, StateError('kaputt'));

    expect(described, contains('kaputt'));
    expect(described, de.errorGeneric('Bad state: kaputt'));
  });

  test('none of the named ones leak the exception text', () {
    // The regression this file exists for.
    const error = PmTilesException('magic 0x1234 at offset 0');

    expect(describeError(de, error), isNot(contains('0x1234')));
    expect(describeError(de, error), isNot(contains('PmTiles')));
  });
}
