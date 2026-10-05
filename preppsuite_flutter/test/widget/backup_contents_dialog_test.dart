import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/settings/application/backup_files.dart';
import 'package:preppsuite_flutter/features/settings/presentation/backup_flow.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

/// What goes into a backup, and what comes back out (#114).
///
/// Everything is chosen to begin with. The large parts can be left out
/// one at a time, because a fifty-gigabyte encyclopedia is a decision of
/// its own; what a restore finds already on the device starts unticked,
/// so it is not copied over itself.
void main() {
  const entries = [
    BackupFileEntry(
      index: 0,
      kind: BackupFileKind.photo,
      label: 'a.jpg',
      size: 1000000,
    ),
    BackupFileEntry(
      index: 1,
      kind: BackupFileKind.photo,
      label: 'b.jpg',
      size: 1000000,
    ),
    BackupFileEntry(
      index: 2,
      kind: BackupFileKind.map,
      label: 'karte.pmtiles',
      size: 2000000000,
    ),
    BackupFileEntry(
      index: 3,
      kind: BackupFileKind.archive,
      label: 'wikipedia_de.zim',
      size: 50000000000,
      meta: {'title': 'Wikipedia'},
    ),
  ];

  /// Opens the dialog and answers a getter for what it returned.
  Future<Set<int>? Function()> open(
    WidgetTester tester, {
    bool restoring = false,
    Set<int> present = const {},
  }) async {
    Set<int>? chosen;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => chosen = await chooseBackupFiles(
                context,
                entries: entries,
                restoring: restoring,
                present: present,
              ),
              child: const Text('los'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('los'));
    await tester.pumpAndSettle();
    return () => chosen;
  }

  testWidgets('everything is in by default, with its size', (tester) async {
    final chosen = await open(tester);
    expect(find.text('Was in die Sicherung kommt'), findsOneWidget);
    expect(find.text('Fotos (2)'), findsOneWidget);
    expect(find.text('Wikipedia (wikipedia_de.zim)'), findsOneWidget);
    expect(find.text('Zusammen etwa 52 GB'), findsOneWidget);

    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(chosen(), {0, 1, 2, 3});
  });

  testWidgets('an archive can be left out', (tester) async {
    final chosen = await open(tester);
    await tester.tap(find.text('Wikipedia (wikipedia_de.zim)'));
    await tester.pumpAndSettle();
    expect(find.text('Zusammen etwa 2.0 GB'), findsOneWidget);

    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(chosen(), {0, 1, 2});
  });

  testWidgets('a restore leaves out what is already here', (tester) async {
    final chosen = await open(tester, restoring: true, present: {3});
    expect(find.text('Was wiederhergestellt wird'), findsOneWidget);
    expect(find.textContaining('schon auf diesem Gerät'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(chosen(), {0, 1, 2});
  });
}
