import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/sync/sync_status.dart';
import 'package:preppsuite_flutter/sync/sync_status_banner.dart';

void main() {
  Future<ProviderContainer> pumpBanner(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SyncStatusBanner(householdId: 'household-1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('shows nothing while sync is healthy', (tester) async {
    final container = await pumpBanner(tester);

    container.read(syncStatusProvider.notifier).recordSuccess(DateTime.now());
    await tester.pumpAndSettle();

    expect(find.text('Änderungen sind noch nicht geteilt'), findsNothing);
    expect(tester.getSize(find.byType(SyncStatusBanner)), Size.zero);
  });

  testWidgets('stays quiet on a single failure after a recent success', (
    tester,
  ) async {
    final container = await pumpBanner(tester);
    final status = container.read(syncStatusProvider.notifier);

    status.recordSuccess(DateTime.now());
    status.recordFailure(DateTime.now());
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(SyncStatusBanner)), Size.zero);
  });

  testWidgets('names the server address when nothing ever synced', (
    tester,
  ) async {
    final container = await pumpBanner(tester);

    container.read(syncStatusProvider.notifier).recordFailure(DateTime.now());
    await tester.pumpAndSettle();

    expect(find.text('Änderungen sind noch nicht geteilt'), findsOneWidget);
    expect(
      find.textContaining('Serveradresse'),
      findsOneWidget,
      reason: 'the likely cause is worth naming instead of a generic error',
    );
  });

  testWidgets('reports how long ago the last success was', (tester) async {
    final container = await pumpBanner(tester);
    final status = container.read(syncStatusProvider.notifier);

    status.recordSuccess(
      DateTime.now().subtract(const Duration(hours: 5, minutes: 20)),
    );
    status.recordFailure(DateTime.now());
    await tester.pumpAndSettle();

    expect(find.textContaining('5 Stunden'), findsOneWidget);
  });

  testWidgets('offers a retry', (tester) async {
    final container = await pumpBanner(tester);

    container.read(syncStatusProvider.notifier).recordFailure(DateTime.now());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextButton, 'Erneut versuchen'), findsOneWidget);
  });

  testWidgets('disappears once a sync succeeds again', (tester) async {
    final container = await pumpBanner(tester);
    final status = container.read(syncStatusProvider.notifier);

    status.recordFailure(DateTime.now());
    await tester.pumpAndSettle();
    expect(find.text('Änderungen sind noch nicht geteilt'), findsOneWidget);

    status.recordSuccess(DateTime.now());
    await tester.pumpAndSettle();

    expect(find.text('Änderungen sind noch nicht geteilt'), findsNothing);
  });
}
