import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/settings_arrival.dart';
import 'package:preppsuite_flutter/features/home/application/broadcast_radio.dart';
import 'package:preppsuite_flutter/features/home/presentation/broadcast_radio_screen.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedProfile extends HouseholdProfileController {
  _FixedProfile(this.profile);

  final HouseholdProfile? profile;

  @override
  Future<HouseholdProfile?> build() async => profile;
}

/// The programmes of the household's Land, and its own frequencies
/// (#267).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AppLocalizations> pump(
    WidgetTester tester, {
    HouseholdProfile? profile,
    Widget screen = const BroadcastRadioScreen(),
  }) async {
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          householdProfileProvider.overrideWith(() => _FixedProfile(profile)),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(
      tester.element(find.byType(BroadcastRadioScreen)),
    )!;
  }

  testWidgets('the household\'s Land, and a frequency written down', (
    tester,
  ) async {
    final l10n = await pump(
      tester,
      profile: const HouseholdProfile(
        id: 'h',
        name: 'Haushalt',
        countryCode: 'DE',
        regionKey: '03241',
      ),
    );

    expect(find.text('NDR 1 Niedersachsen'), findsOneWidget);
    expect(find.text('NDR Info'), findsOneWidget);
    expect(find.text('Deutschlandfunk'), findsOneWidget);
    expect(find.text('BAYERN 1'), findsNothing);

    await tester.tap(find.text(l10n.broadcastRadioFrequencyAdd).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '95,63');
    await tester.tap(find.text(l10n.saveButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.broadcastRadioFrequencyInvalid), findsOneWidget);

    await tester.enterText(find.byType(TextField), '95,6');
    await tester.tap(find.text(l10n.saveButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.broadcastRadioFrequencyHere('95,6')), findsOneWidget);
    expect(await const BroadcastFrequencyStore().load(), {
      'ndr1-niedersachsen': 95.6,
    });
  });

  testWidgets('without a household it asks for the Land', (tester) async {
    final l10n = await pump(tester);

    expect(find.text(l10n.broadcastRadioChooseState), findsOneWidget);
    // Deutschlandfunk is everywhere, Land or not.
    expect(find.text('Deutschlandfunk'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bayern').last);
    await tester.pumpAndSettle();
    expect(find.text('BAYERN 1'), findsOneWidget);
    expect(find.text('BR24'), findsOneWidget);
  });

  testWidgets('a frequency from another device appears where it is open', (
    tester,
  ) async {
    final l10n = await pump(
      tester,
      profile: const HouseholdProfile(
        id: 'h',
        name: 'Haushalt',
        countryCode: 'DE',
        regionKey: '09162',
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(BroadcastFrequencyStore.key, '{"bayern1": 89.2}');
    announceSettingsArrival();
    await tester.pumpAndSettle();

    expect(find.text(l10n.broadcastRadioFrequencyHere('89,2')), findsOneWidget);
  });

  testWidgets(
    'in the emergency access nothing of the household shows (#269)',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        BroadcastFrequencyStore.key: '{"ndr1-niedersachsen": 95.6}',
      });
      final l10n = await pump(
        tester,
        profile: const HouseholdProfile(
          id: 'h',
          name: 'Haushalt',
          countryCode: 'DE',
          regionKey: '03241',
        ),
        screen: const BroadcastRadioScreen.withoutHousehold(),
      );

      // Not the household's Land, not its frequency, and no way to write
      // one down.
      expect(find.text(l10n.broadcastRadioChooseState), findsOneWidget);
      expect(find.text('NDR 1 Niedersachsen'), findsNothing);
      expect(find.text(l10n.broadcastRadioFrequencyHere('95,6')), findsNothing);
      expect(find.text(l10n.broadcastRadioFrequencyAdd), findsNothing);
      expect(find.text(l10n.broadcastRadioLockedNote), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Niedersachsen').last);
      await tester.pumpAndSettle();
      expect(find.text('NDR 1 Niedersachsen'), findsOneWidget);
      expect(find.text(l10n.broadcastRadioFrequencyHere('95,6')), findsNothing);
    },
  );
}
