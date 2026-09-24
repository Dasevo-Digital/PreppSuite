import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:preppsuite_flutter/features/checklists/application/checklist_providers.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/warning_list_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';

class _Profile extends HouseholdProfileController {
  @override
  Future<HouseholdProfile?> build() async => const HouseholdProfile(
    id: 'h',
    name: 'Haushalt',
    countryCode: 'DE',
    regionKey: '053340000000',
  );
}

/// The one thing a warning offered before this was the official page in a
/// browser — on the screen somebody opens because something is happening,
/// and usually without a network. The app holds the steps for exactly that
/// hazard, offline, and nothing led there.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Warning warningFor(String eventType) => Warning(
    source: 'bbk',
    externalId: 'w1',
    countryCode: 'DE',
    regionKey: '053340000000',
    severity: 'severe',
    eventType: eventType,
    headline: eventType,
    effective: DateTime.utc(2026),
    sent: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    notified: false,
  );

  ChecklistTemplate template(String clientId, String title) =>
      ChecklistTemplate(
        clientId: clientId,
        householdId: 'h',
        title: title,
        category: 'hazards',
        kind: 'response',
        isBuiltIn: true,
        updatedAt: DateTime.utc(2024),
        dirty: false,
      );

  Future<void> show(WidgetTester tester, String eventType) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          householdProfileProvider.overrideWith(_Profile.new),
          allWarningsProvider.overrideWith(
            (ref) => Stream.value([warningFor(eventType)]),
          ),
          checklistTemplatesProvider('h').overrideWith(
            (ref) => Stream.value([
              template(
                '00000000-0000-4000-8000-000000000020',
                'Hochwasser: wenn es soweit ist',
              ),
            ]),
          ),
          allChecklistItemsProvider(
            'h',
          ).overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WarningListScreen(
            profile: const HouseholdProfile(
              id: 'h',
              name: 'Haushalt',
              countryCode: 'DE',
              regionKey: '053340000000',
            ),
            now: DateTime.utc(2026, 5, 4),
          ),
        ),
      ),
    );
    for (var turn = 0; turn < 8; turn++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // The details live inside a collapsed ExpansionTile: the list shows
    // headlines, and what a warning means is one tap in.
    await tester.tap(find.byType(ExpansionTile).first);
    for (var turn = 0; turn < 12; turn++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('a flood warning leads to the flood list', (tester) async {
    await show(tester, 'Hochwasser');

    expect(find.text('Was jetzt zu tun ist'), findsOneWidget);
  });

  testWidgets('an event with no list offers nothing', (tester) async {
    // An offer that does not fit is worse than none here.
    await show(tester, 'Glatteis');

    expect(find.text('Was jetzt zu tun ist'), findsNothing);
  });

  testWidgets('and nothing when the list is not seeded yet', (tester) async {
    // A household seeded before the list existed and not yet relaunched.
    // A button that opens nothing would be worse than no button.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          householdProfileProvider.overrideWith(_Profile.new),
          allWarningsProvider.overrideWith(
            (ref) => Stream.value([warningFor('Hochwasser')]),
          ),
          checklistTemplatesProvider(
            'h',
          ).overrideWith((ref) => Stream.value([])),
          allChecklistItemsProvider(
            'h',
          ).overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WarningListScreen(
            profile: const HouseholdProfile(
              id: 'h',
              name: 'Haushalt',
              countryCode: 'DE',
              regionKey: '053340000000',
            ),
            now: DateTime.utc(2026, 5, 4),
          ),
        ),
      ),
    );
    for (var turn = 0; turn < 8; turn++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Was jetzt zu tun ist'), findsNothing);
  });
}
