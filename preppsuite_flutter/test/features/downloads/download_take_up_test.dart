import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/downloads/application/download_folder.dart';
import 'package:preppsuite_flutter/features/downloads/application/download_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What happens to a finished download once it is handed over.
///
/// These archives are tens of gigabytes and take hours, and the banner
/// exists precisely so the user can go elsewhere meanwhile — so the
/// screen that started a download is normally gone by the time it
/// arrives. A take-up that closed over that screen's `WidgetRef` threw
/// the moment it ran; nothing caught it, and the banner went on saying
/// the download had finished. That is how a download folder came to hold
/// nine archives and the library none.
final markerProvider = Provider<String>((ref) => 'library');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the take-up of a finished download', () {
    late Directory folder;
    late ArchiveDownloadRequest request;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();

      folder = Directory.systemTemp.createTempSync('preppsuite-takeup');
      await const DownloadFolder().use(folder.path);

      // Already on disk, so start() goes straight to the take-up — the
      // same branch a finished transfer reaches, without a server.
      File(
        '${folder.path}${Platform.pathSeparator}archive.zim',
      ).writeAsStringSync('not really an archive');
      request = ArchiveDownloadRequest(
        url: Uri.parse('https://example.invalid/archive.zim'),
        fileName: 'archive.zim',
        label: 'Klexikon',
      );
    });

    tearDown(() {
      container.dispose();
      folder.deleteSync(recursive: true);
    });

    test('is handed a ref that reads providers', () async {
      String? seen;
      await container
          .read(archiveDownloadProvider.notifier)
          .start(
            request,
            onFinished: (downloadRef, path, label) async {
              seen = downloadRef.read(markerProvider);
              return null;
            },
          );

      expect(seen, 'library');
      final state = container.read(archiveDownloadProvider);
      expect(state.finishedPath, endsWith('archive.zim'));
      expect(state.takeUpProblem, isNull);
    });

    test('says so when it throws, instead of announcing success', () async {
      await container
          .read(archiveDownloadProvider.notifier)
          .start(
            request,
            onFinished: (downloadRef, path, label) async =>
                throw StateError('the screen is gone'),
          );

      final state = container.read(archiveDownloadProvider);
      expect(state.finishedPath, isNotNull, reason: 'the file did arrive');
      expect(
        state.takeUpProblem,
        contains('the screen is gone'),
        reason: 'the banner must not say the download simply finished',
      );
    });
  });

  testWidgets('a callback holding a screen ref fails once the screen is gone', (
    tester,
  ) async {
    // Why the callback is handed the notifier's ref rather than closing
    // over the starting screen's. No download here: this is about the
    // lifetime of a `WidgetRef`, which is what the old shape got wrong.
    late Future<String> Function() later;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              later = () async => ref.read(markerProvider);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(await later(), 'library', reason: 'while the screen is there');

    // The user goes back to the encyclopedia; the download runs on.
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: Placeholder())),
    );

    await expectLater(later(), throwsA(anything));
  });
}
