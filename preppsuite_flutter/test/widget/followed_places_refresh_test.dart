import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/settings/presentation/followed_places_screen.dart';
import 'package:preppsuite_flutter/features/warnings/application/dwd_areas.dart';
import 'package:preppsuite_flutter/features/warnings/application/dwd_areas_provider.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_filter.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Profile extends HouseholdProfileController {
  _Profile(this.initial);

  final HouseholdProfile initial;

  @override
  Future<HouseholdProfile?> build() async => initial;
}

/// "Meine Warnorte" is opened as a route of its own with the household as
/// it was. A place added there showed only after the app had been
/// restarted (#368, reported on an iPhone).
void main() {
  final areas = DwdAreas.parse('''
# name;district;state
Stadt Braunschweig;03101;NI
Stadt Worms;07319;RP
''');
  const initial = HouseholdProfile(
    id: 'h1',
    name: 'Test',
    countryCode: 'DE',
    regionKey: '07319',
  );

  Future<ProviderContainer> open(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        dwdAreasProvider.overrideWith((ref) async => areas),
        householdProfileProvider.overrideWith(() => _Profile(initial)),
      ],
    );
    addTearDown(container.dispose);
    await tester.binding.setSurfaceSize(const Size(500, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FollowedPlacesScreen(profile: initial),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('a place added shows at once, and goes at once', (tester) async {
    final container = await open(tester);
    expect(find.text('Niedersachsen'), findsNothing);

    const lowerSaxony = WarningRegion(
      kind: WarningRegionKind.bundesland,
      value: 'NI',
    );
    await tester.runAsync(
      () => container
          .read(householdProfileProvider.notifier)
          .addRegion(lowerSaxony),
    );
    await tester.pumpAndSettle();
    expect(find.text('Niedersachsen'), findsOneWidget);

    await tester.runAsync(
      () => container
          .read(householdProfileProvider.notifier)
          .removeRegion(lowerSaxony),
    );
    await tester.pumpAndSettle();
    expect(find.text('Niedersachsen'), findsNothing);
  });

  testWidgets('a changed own region shows at once', (tester) async {
    final container = await open(tester);
    expect(find.textContaining('Stadt Worms'), findsOneWidget);

    await tester.runAsync(
      () => container
          .read(householdProfileProvider.notifier)
          .save(initial.copyWith(regionKey: '031010000000')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Stadt Braunschweig'), findsOneWidget);
    expect(find.textContaining('Stadt Worms'), findsNothing);
  });
}
