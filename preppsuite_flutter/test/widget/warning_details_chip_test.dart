import 'dart:math' as math;

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
import 'package:preppsuite_flutter/model/categories.dart';
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

double _luminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The chip in an opened warning, rendered and measured (#322).
///
/// `warning_severity_colors_test` holds the pair of colours to 4.5:1. The
/// chip used the background and the icon's colour and left its label to
/// the theme, which that test could not see: "Extreme" stood at 1.32:1 in
/// the dark and 2.61:1 in the light.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  for (final (name, theme) in [
    ('light', appLightTheme),
    ('dark', appDarkTheme),
  ]) {
    for (final severity in WarningSeverity.values) {
      testWidgets('${severity.name} can be read in the $name theme', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(500, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final warning = Warning(
          source: 'bbk',
          externalId: 'w',
          countryCode: 'DE',
          regionKey: '05334',
          severity: severity.name,
          eventType: 'Gefahr',
          headline: 'Gefahr',
          effective: DateTime.utc(2026),
          sent: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          notified: false,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              warningSyncControllerProvider.overrideWith2(FakeWarningSync.new),
              appDatabaseProvider.overrideWithValue(db),
              householdProfileProvider.overrideWith(_Profile.new),
              allWarningsProvider.overrideWith(
                (ref) => Stream.value([warning]),
              ),
              checklistTemplatesProvider(
                'h',
              ).overrideWith(
                (ref) => Stream.value(const <ChecklistTemplate>[]),
              ),
              allChecklistItemsProvider(
                'h',
              ).overrideWith((ref) => Stream.value([])),
            ],
            child: MaterialApp(
              theme: theme,
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

        await tester.tap(find.byType(ExpansionTile));
        for (var turn = 0; turn < 8; turn++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        final chip = tester.widget<Chip>(
          find.descendant(
            of: find.byType(ExpansionTile),
            matching: find.byType(Chip),
          ),
        );
        final label = tester.widget<RichText>(
          find.descendant(
            of: find.byWidget(chip.label),
            matching: find.byType(RichText),
          ),
        );
        expect(
          _contrast(label.text.style!.color!, chip.backgroundColor!),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  }
}
