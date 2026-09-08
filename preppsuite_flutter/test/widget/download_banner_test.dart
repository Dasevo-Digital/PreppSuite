import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/downloads/application/download_providers.dart';
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
}
