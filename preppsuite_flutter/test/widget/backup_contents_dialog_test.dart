import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/settings/application/backup_files.dart';
import 'package:preppsuite_flutter/features/settings/presentation/backup_flow.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

/// The list of what goes into a backup, and what comes back out (#132).
///
/// A backup that silently leaves the photos out, or a restore that copies
/// fifty gigabytes the device already has, is the kind of mistake nobody
/// notices until the day it matters.
void main() {
  const entries = [
    BackupFileEntry(
      index: 0,
      kind: BackupFileKind.photo,
      label: 'a.jpg',
      size: 1000,
    ),
    BackupFileEntry(
      index: 1,
      kind: BackupFileKind.photo,
      label: 'b.jpg',
      size: 1000,
    ),
    BackupFileEntry(
      index: 2,
      kind: BackupFileKind.document,
      label: 'police.pdf',
      size: 2000,
    ),
    BackupFileEntry(
      index: 3,
      kind: BackupFileKind.archive,
      label: 'wikipedia_de_all_maxi.zim',
      size: 50000000000,
      meta: {'title': 'Wikipedia'},
    ),
  ];

  late AppLocalizations l10n;
  Set<int>? answer;
  var answered = false;

  Future<void> show(
    WidgetTester tester, {
    required bool restoring,
    Set<int> present = const {},
  }) async {
    answered = false;
    answer = null;
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  answer = await chooseBackupFiles(
                    context,
                    entries: entries,
                    restoring: restoring,
                    present: present,
                  );
                  answered = true;
                },
                child: const Text('los'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('los'));
    await tester.pumpAndSettle();
  }

  testWidgets('a backup takes everything unless told otherwise', (
    tester,
  ) async {
    await show(tester, restoring: false);
    expect(find.text(l10n.backupContentsTitle), findsOneWidget);
    // The photos are one line, not one per picture.
    expect(find.text(l10n.backupContentsPhotos(2)), findsOneWidget);
    expect(find.text('Wikipedia (wikipedia_de_all_maxi.zim)'), findsOneWidget);

    await tester.tap(find.text(l10n.backupContentsContinue));
    await tester.pumpAndSettle();
    expect(answer, {0, 1, 2, 3});
  });

  testWidgets('leaving the encyclopedia out leaves out exactly that', (
    tester,
  ) async {
    await show(tester, restoring: false);
    await tester.tap(find.text('Wikipedia (wikipedia_de_all_maxi.zim)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.backupContentsContinue));
    await tester.pumpAndSettle();
    expect(answer, {0, 1, 2});
  });

  testWidgets('what this device already has is not restored again', (
    tester,
  ) async {
    await show(tester, restoring: true, present: {3});
    expect(find.text(l10n.backupRestoreContentsTitle), findsOneWidget);
    expect(
      find.textContaining(l10n.backupContentsPresent),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.backupContentsContinue));
    await tester.pumpAndSettle();
    expect(answer, {0, 1, 2});
  });

  testWidgets('backing out answers nothing, not an empty choice', (
    tester,
  ) async {
    await show(tester, restoring: true);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(answered, isTrue);
    expect(answer, isNull);
  });

  testWidgets('the summary line names what did not come back', (
    tester,
  ) async {
    await show(tester, restoring: true);
    expect(describeFilesRestored(l10n, null), isNull);
    expect(
      describeFilesRestored(
        l10n,
        const BackupFilesRestored(restored: 0, failed: []),
      ),
      isNull,
    );
    final line = describeFilesRestored(
      l10n,
      const BackupFilesRestored(restored: 3, failed: ['police.pdf']),
    )!;
    expect(line, contains(l10n.backupFilesRestored(3)));
    expect(line, contains('police.pdf'));
  });
}
