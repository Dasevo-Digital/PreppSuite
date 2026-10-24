import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/emergency_access.dart';
import 'package:preppsuite_flutter/core/error_log.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/household/presentation/household_gate.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/features/settings/presentation/error_log_card.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';

class _Broken extends HouseholdProfileController {
  static var builds = 0;

  @override
  Future<HouseholdProfile?> build() {
    builds++;
    return Future.error(const FileSystemException('disk went away'));
  }
}

/// A database that does not open is not a dead end (#136).
void main() {
  testWidgets('says what happened, offers a retry and the emergency help', (
    tester,
  ) async {
    _Broken.builds = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [householdProfileProvider.overrideWith(_Broken.new)],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HouseholdGate(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Der Haushalt lässt sich gerade nicht laden'),
      findsOneWidget,
    );
    expect(find.byType(EmergencyAccessButton), findsOneWidget);

    // Riverpod retries a failed provider by itself as well; the button is
    // one more try now, not after the next back-off.
    final before = _Broken.builds;
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pump();
    expect(_Broken.builds, greaterThan(before));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EmergencyAccessButton));
    await tester.pumpAndSettle();
    expect(find.byType(EmergencyAccessScreen), findsOneWidget);
  });
  testWidgets('says why, in the error log it offers right there (#210)', (
    tester,
  ) async {
    // On a phone after the update to 2.6.3 this screen said only "an
    // unexpected error", and the why reached no log: the settings with
    // the log sit behind this very screen.
    await tester.runAsync(ErrorLog.instance.clear);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [householdProfileProvider.overrideWith(_Unknown.new)],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HouseholdGate(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The sentence stays plain on purpose ...
    expect(find.textContaining('unerwarteter Fehler'), findsOneWidget);
    // ... and what failed is in the log, once, under what it was doing.
    final log = (await tester.runAsync(ErrorLog.instance.read))!;
    expect(log, contains('Haushalt laden'));
    expect(log, contains('ArgumentError'));
    expect('=== '.allMatches(log), hasLength(1));
    expect(find.byType(ErrorLogCard), findsOneWidget);
    await tester.runAsync(ErrorLog.instance.clear);
  });
}

class _Unknown extends HouseholdProfileController {
  @override
  Future<HouseholdProfile?> build() =>
      Future.error(ArgumentError.value('Instance of JObject'));
}
