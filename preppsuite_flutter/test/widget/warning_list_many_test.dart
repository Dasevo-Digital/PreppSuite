import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:preppsuite_flutter/features/checklists/application/checklist_providers.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_sync_controller.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/warning_list_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
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

/// A wide window lays warnings out in columns, and columns build every
/// block. A nationwide frost had 808 warnings out on 2026-11-06: 722 ms and
/// 67,930 elements per rebuild, for every key in the search field (#300).
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Warning warning(int number) => Warning(
    source: 'meteoalarm',
    externalId: 'w$number',
    countryCode: 'DE',
    regionKey: '053340000000',
    severity: 'minor',
    eventType: 'Frost',
    headline: 'Frost $number',
    effective: DateTime.utc(2026),
    sent: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    notified: false,
  );

  Future<int> tilesBuilt(WidgetTester tester, int warnings) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          warningSyncControllerProvider.overrideWith2(FakeWarningSync.new),
          appDatabaseProvider.overrideWithValue(db),
          householdProfileProvider.overrideWith(_Profile.new),
          allWarningsProvider.overrideWith(
            (ref) => Stream.value([
              for (var number = 0; number < warnings; number++) warning(number),
            ]),
          ),
          checklistTemplatesProvider('h').overrideWith(
            (ref) => Stream.value(const <ChecklistTemplate>[]),
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
            profile: _household,
            now: DateTime.utc(2026, 5, 4),
          ),
        ),
      ),
    );
    for (var turn = 0; turn < 8; turn++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    return find.byType(ExpansionTile).evaluate().length;
  }

  testWidgets('a few warnings stay in columns', (tester) async {
    expect(await tilesBuilt(tester, 30), 30);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('a long list builds only what is on screen', (tester) async {
    expect(await tilesBuilt(tester, 300), lessThan(30));
  });
}
