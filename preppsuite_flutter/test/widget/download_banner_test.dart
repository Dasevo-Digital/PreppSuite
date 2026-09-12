import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/downloads/application/archive_downloader.dart';
import 'package:preppsuite_flutter/features/downloads/application/download_providers.dart';
import 'package:preppsuite_flutter/features/downloads/application/download_rate.dart';
import 'package:preppsuite_flutter/features/downloads/presentation/download_banner.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

/// A download that arrives and is then refused is the case that used to
/// go unsaid: the banner reported success, the feature went on showing no
/// archive, and nothing anywhere named the reason.
class _FixedDownload extends ArchiveDownloadController {
  _FixedDownload(this.fixed);

  final ArchiveDownloadState fixed;

  @override
  ArchiveDownloadState build() => fixed;
}

void main() {
  final request = ArchiveDownloadRequest(
    url: Uri.parse('https://download.kiwix.org/zim/wikipedia_de_all_nopic.zim'),
    fileName: 'wikipedia_de_all_nopic.zim',
    label: 'Wikipedia (Deutsch)',
  );

  Future<void> show(WidgetTester tester, ArchiveDownloadState state) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          archiveDownloadProvider.overrideWith(() => _FixedDownload(state)),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: DownloadBanner()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a finished download that was taken into use says so', (
    tester,
  ) async {
    await show(
      tester,
      ArchiveDownloadState(
        request: request,
        finishedPath: '/tmp/wikipedia_de_all_nopic.zim',
      ),
    );

    expect(find.textContaining('ist fertig geladen'), findsOneWidget);
  });

  testWidgets('one that could not be opened names the reason', (tester) async {
    await show(
      tester,
      ArchiveDownloadState(
        request: request,
        finishedPath: '/tmp/wikipedia_de_all_nopic.zim',
        takeUpProblem: 'Erwartet wird ein ZIM-Archiv.',
      ),
    );

    expect(find.textContaining('lässt sich aber nicht öffnen'), findsOneWidget);
    expect(
      find.textContaining('Erwartet wird ein ZIM-Archiv.'),
      findsOneWidget,
    );
    expect(find.textContaining('ist fertig geladen'), findsNothing);
  });

  testWidgets('nothing in flight shows nothing at all', (tester) async {
    await show(tester, const ArchiveDownloadState());

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('the download banner meets the accessibility guidelines', (
    tester,
  ) async {
    await show(
      tester,
      ArchiveDownloadState(
        request: request,
        finishedPath: '/tmp/wikipedia_de_all_nopic.zim',
      ),
    );
    await expectAccessible(tester);
  });

  testWidgets('the download banner survives twice the font size', (
    tester,
  ) async {
    useLargeText(tester);
    await show(
      tester,
      ArchiveDownloadState(
        request: request,
        finishedPath: '/tmp/wikipedia_de_all_nopic.zim',
      ),
    );
  });

  testWidgets('the bar tells a screen reader how far along it is', (
    tester,
  ) async {
    // The figures beside the bar are readable, but only by navigating to
    // them. A percentage on the bar itself is what somebody hears while
    // passing over it.
    final handle = tester.ensureSemantics();
    await show(
      tester,
      ArchiveDownloadState(
        request: request,
        progress: const DownloadProgress(received: 3, total: 4),
      ),
    );

    expect(
      tester.getSemantics(find.byType(LinearProgressIndicator)).value,
      '75 %',
    );
    handle.dispose();
  });

  testWidgets('a download without a total says no percentage at all', (
    tester,
  ) async {
    // A mirror behind a redirect gives no length. "0 %" would be a lie
    // that reads exactly like a download that is not moving.
    final handle = tester.ensureSemantics();
    await show(
      tester,
      ArchiveDownloadState(
        request: request,
        progress: const DownloadProgress(received: 3, total: null),
      ),
    );

    expect(tester.getSemantics(find.byType(LinearProgressIndicator)).value, '');
    handle.dispose();
  });

  testWidgets('a running download is not announced over and over', (
    tester,
  ) async {
    // A live region on the running banner would talk over everything else
    // for as long as the download lasts — most of an afternoon for a
    // 52 GB archive.
    final handle = tester.ensureSemantics();
    await show(
      tester,
      ArchiveDownloadState(
        request: request,
        progress: const DownloadProgress(received: 3, total: 4),
      ),
    );

    expect(liveRegions(tester), isEmpty);
    handle.dispose();
  });

  testWidgets('a finished download announces itself', (tester) async {
    // The banner is shown wherever the user happens to be, so this is the
    // one moment worth interrupting for.
    final handle = tester.ensureSemantics();
    await show(
      tester,
      ArchiveDownloadState(request: request, finishedPath: '/tmp/w.zim'),
    );

    expect(liveRegions(tester), hasLength(1));
    handle.dispose();
  });

  testWidgets('a failed download announces itself too', (tester) async {
    final handle = tester.ensureSemantics();
    await show(
      tester,
      ArchiveDownloadState(request: request, error: 'kaputt'),
    );

    expect(liveRegions(tester), hasLength(1));
    handle.dispose();
  });

  group('while it is running', () {
    // "1,2 GB von 52 GB" answers how far along, in arithmetic, and says
    // nothing about when the archive will be usable — which for a file
    // this size is the only question anybody has.
    testWidgets('the percentage is spelled out', (tester) async {
      await show(
        tester,
        ArchiveDownloadState(
          request: request,
          progress: const DownloadProgress(
            received: 4500000000,
            total: 10000000000,
          ),
        ),
      );

      expect(find.textContaining('45'), findsOneWidget);
    });

    testWidgets('speed and remaining time are shown once known', (
      tester,
    ) async {
      await show(
        tester,
        ArchiveDownloadState(
          request: request,
          progress: const DownloadProgress(
            received: 4500000000,
            total: 10000000000,
          ),
          rate: const DownloadRate(
            bytesPerSecond: 5500000,
            remaining: Duration(minutes: 16, seconds: 40),
          ),
        ),
      );

      expect(find.textContaining('5.5 MB/s'), findsOneWidget);
      expect(find.textContaining('noch 16 min'), findsOneWidget);
    });

    testWidgets('the first seconds say nothing rather than nonsense', (
      tester,
    ) async {
      // The rate is null until there is enough of a sample; the bar and
      // the sizes still have to be there.
      await show(
        tester,
        ArchiveDownloadState(
          request: request,
          progress: const DownloadProgress(received: 1000, total: 10000000000),
        ),
      );

      expect(find.textContaining('MB/s'), findsNothing);
      expect(find.textContaining('noch'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('a download with no stated total still shows a bar', (
      tester,
    ) async {
      // A mirror behind a redirect sometimes gives no length at all.
      await show(
        tester,
        ArchiveDownloadState(
          request: request,
          progress: const DownloadProgress(received: 1000000, total: null),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('an hour or more reads in hours', (tester) async {
      await show(
        tester,
        ArchiveDownloadState(
          request: request,
          progress: const DownloadProgress(
            received: 1000000000,
            total: 52000000000,
          ),
          rate: const DownloadRate(
            bytesPerSecond: 4000000,
            remaining: Duration(hours: 3, minutes: 32),
          ),
        ),
      );

      expect(find.textContaining('noch 3 h 32 min'), findsOneWidget);
    });
  });

  testWidgets(
    'a dropped connection is said out loud, not left to a still bar',
    (
      tester,
    ) async {
      // The wait before the next attempt runs up to a minute. A progress
      // bar that simply stops for that long reads as a hung app.
      await show(
        tester,
        ArchiveDownloadState(
          request: request,
          progress: const DownloadProgress(
            received: 4_000_000,
            total: 11_000_000,
            resuming: true,
          ),
          rate: const DownloadRate(
            bytesPerSecond: 2_000_000,
            remaining: Duration(minutes: 4),
          ),
        ),
      );

      expect(
        find.textContaining('wird fortgesetzt'),
        findsOneWidget,
        reason: 'the pause has to be named',
      );
      // Neither of these is true while nothing is being transferred, and a
      // remaining time counted from a speed that has stopped is a guess
      // dressed as a measurement.
      expect(find.textContaining('MB/s'), findsNothing);
      expect(find.textContaining('4 Minuten'), findsNothing);
      // What is still true stays.
      expect(find.textContaining('36'), findsOneWidget);
    },
  );
}
