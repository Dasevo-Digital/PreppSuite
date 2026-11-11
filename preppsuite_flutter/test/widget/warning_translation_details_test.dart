import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:preppsuite_flutter/core/app_theme.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_providers.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_sync_controller.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/warning_list_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_translations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';

import 'fake_warning_sync.dart';

const _household = HouseholdProfile(
  id: 'h',
  name: 'Haushalt',
  countryCode: 'DE',
  regionKey: '053340000000',
);

class _Profile extends HouseholdProfileController {
  @override
  Future<HouseholdProfile?> build() async => _household;
}

/// An opened warning in the app's language, the German beneath it, and a
/// second language on request (#357).
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  final warning = Warning(
    source: 'bbk',
    externalId: 'w',
    countryCode: 'DE',
    regionKey: '05334',
    severity: 'severe',
    eventType: 'Abkochgebot',
    headline: 'Abkochgebot',
    description: 'Leitungswasser nur abgekocht trinken.',
    instruction: 'Wasser abkochen.',
    // As MoWaS translates: the event's name and what to do (#357).
    translationsJson: encodeWarningTranslations({
      'es': const WarningTranslation(
        event: 'Hervir el agua',
        instruction: 'Hierva el agua.',
      ),
      'tr': const WarningTranslation(
        event: 'Suyu kaynatın',
        instruction: 'Suyu kaynatmadan içmeyin.',
      ),
    }),
    messageType: 'Cancel',
    effective: DateTime.utc(2026),
    sent: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    notified: false,
  );

  Future<void> open(WidgetTester tester, Locale locale) async {
    await tester.binding.setSurfaceSize(const Size(500, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          warningSyncControllerProvider.overrideWith2(FakeWarningSync.new),
          appDatabaseProvider.overrideWithValue(db),
          householdProfileProvider.overrideWith(_Profile.new),
          allWarningsProvider.overrideWith((ref) => Stream.value([warning])),
          checklistTemplatesProvider(
            'h',
          ).overrideWith((ref) => Stream.value(const <ChecklistTemplate>[])),
          allChecklistItemsProvider('h')
              .overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: appLightTheme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WarningListScreen(
            profile: _household,
            now: DateTime.utc(2026, 5, 4),
          ),
        ),
      ),
    );
    for (var turn = 0; turn < 8; turn++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.byType(ExpansionTile).first);
    for (var turn = 0; turn < 8; turn++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('in Spanish the Spanish, with the German beneath', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await open(tester, const Locale('es'));

    // The German headline stays, after the event's name, and the end of
    // the warning is said in Spanish: the German says it in German only.
    expect(
      find.text('Fin del aviso: Hervir el agua – Abkochgebot'),
      findsWidgets,
    );
    expect(find.text('Hervir el agua'), findsNothing);
    expect(find.text('Hierva el agua.'), findsOneWidget);
    expect(find.text('Texto oficial en alemán'), findsOneWidget);
    expect(
      find.text('Fin del aviso: este mensaje pone fin al aviso.'),
      findsOneWidget,
    );
  });

  testWidgets('in German the German, and no original to unfold', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await open(tester, const Locale('de'));

    expect(find.text('Abkochgebot'), findsWidgets);
    expect(find.text('Amtlicher Text auf Deutsch'), findsNothing);
  });

  testWidgets('an all-clear says so in a second language the app speaks', (
    tester,
  ) async {
    // The English the BBK sent for Husum's all-clear still said to avoid
    // the area; the section has to say that the warning is over (#367).
    SharedPreferences.setMockInitialValues({'warningExtraLanguage': 'es'});
    await open(tester, const Locale('de'));

    expect(find.text('Amtliche Übersetzung: Español'), findsOneWidget);
    expect(
      find.text('Fin del aviso: este mensaje pone fin al aviso.'),
      findsOneWidget,
    );
    expect(
      find.text('Entwarnung: Diese Meldung hebt die Warnung auf.'),
      findsOneWidget,
    );
  });

  testWidgets('a second language chosen on this device', (tester) async {
    SharedPreferences.setMockInitialValues({'warningExtraLanguage': 'tr'});
    await open(tester, const Locale('de'));

    expect(find.text('Amtliche Übersetzung: Türkçe'), findsOneWidget);
    // No Turkish word for it the BBK gave: the German note above is the
    // only one, not repeated in the section (#367).
    expect(
      find.text('Entwarnung: Diese Meldung hebt die Warnung auf.'),
      findsOneWidget,
    );
    expect(find.text('Suyu kaynatın'), findsOneWidget);
    expect(find.text('Suyu kaynatmadan içmeyin.'), findsOneWidget);
    // Only what the language says: the German description is above.
    expect(
      find.text('Leitungswasser nur abgekocht trinken.'),
      findsOneWidget,
    );
  });
}
