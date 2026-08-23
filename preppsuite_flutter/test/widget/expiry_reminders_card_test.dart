import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/expiry_reminder_provider.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/expiry_reminders_card.dart';
import 'package:preppsuite_flutter/core/notifications_provider.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> pumpCard(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) =>
                  ExpiryRemindersCard(l10n: AppLocalizations.of(context)!),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('offers every selectable lead time as a chip', (tester) async {
    await pumpCard(tester);

    expect(
      find.byType(FilterChip),
      findsNWidgets(selectableExpiryLeadDays.length),
    );
    expect(find.text('30 Tage'), findsOneWidget);
    // The one-day chip has its own label so it does not read "1 Tage".
    expect(find.text('1 Tag'), findsOneWidget);
  });

  testWidgets('the default lead times start out selected', (tester) async {
    await pumpCard(tester);

    final selected = tester
        .widgetList<FilterChip>(find.byType(FilterChip))
        .where((chip) => chip.selected)
        .map((chip) => (chip.label as Text).data)
        .toList();

    expect(selected, ['30 Tage', '7 Tage']);
  });

  testWidgets('tapping a chip toggles it on and off in the provider', (
    tester,
  ) async {
    final container = await pumpCard(tester);

    await tester.tap(find.text('14 Tage'));
    await tester.pumpAndSettle();
    expect(container.read(expiryLeadDaysProvider), contains(14));

    await tester.tap(find.text('14 Tage'));
    await tester.pumpAndSettle();
    expect(container.read(expiryLeadDaysProvider), isNot(contains(14)));
  });

  testWidgets('says reminders are off while notifications are disabled', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(
      find.text(
        'Schalte oben die Benachrichtigungen ein, damit Erinnerungen '
        'geplant werden.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('explains that no lead time means no reminders', (tester) async {
    final container = await pumpCard(tester);

    // Notifications on, but every lead time cleared — a valid choice that
    // must not look like the feature is broken.
    container.read(notificationsEnabledProvider.notifier).state = true;
    await container.read(expiryLeadDaysProvider.notifier).setLeadDays([]);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Keine Vorlaufzeit gewählt — es werden keine Erinnerungen geplant.',
      ),
      findsOneWidget,
    );
  });
}
