import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/warning_day_notice.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

/// The notice above the warning list.
///
/// On the warning day this app shows a test warning that looks like any
/// other, because it arrives down the same official feeds. The notice is
/// what stands between frightening somebody and teaching them to distrust
/// the list.
void main() {
  Future<void> show(WidgetTester tester, {DateTime? now}) async {
    await tester.binding.setSurfaceSize(const Size(420, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return ListView(
                children: [?WarningDayNotice.forList(l10n, now: now)],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('on the day it says today, not "in 0 days"', (tester) async {
    await show(tester, now: DateTime(2026, 9, 10, 8));

    expect(find.text('Heute ist bundesweiter Warntag'), findsOneWidget);
    expect(find.textContaining('in 0'), findsNothing);
  });

  testWidgets('the day before it counts one day, in the singular', (
    tester,
  ) async {
    await show(tester, now: DateTime(2026, 9, 9));

    expect(find.text('Bundesweiter Warntag in einem Tag'), findsOneWidget);
  });

  testWidgets('a week ahead it is already there', (tester) async {
    await show(tester, now: DateTime(2026, 9, 3));

    expect(find.text('Bundesweiter Warntag in 7 Tagen'), findsOneWidget);
  });

  testWidgets('eight days ahead it stays away', (tester) async {
    // The warning list is this screen's job; the notice is a guest on it
    // and must not stand there for a month.
    await show(tester, now: DateTime(2026, 9, 2));

    expect(find.byType(WarningDayNotice), findsNothing);
  });

  testWidgets('and it is gone again the day after', (tester) async {
    await show(tester, now: DateTime(2026, 9, 11));

    expect(find.byType(WarningDayNotice), findsNothing);
  });

  testWidgets('it names both times, so a test warning is recognisable', (
    tester,
  ) async {
    // Somebody who reads 11:45 knows the all-clear is part of the
    // exercise. Without it, an all-clear looks like a second event.
    await show(tester, now: DateTime(2026, 9, 10));

    expect(find.textContaining('11:00'), findsOneWidget);
    expect(find.textContaining('11:45'), findsOneWidget);
  });

  testWidgets('it meets the accessibility guidelines', (tester) async {
    await show(tester, now: DateTime(2026, 9, 10));
    await expectAccessible(tester);
  });

  testWidgets('it survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester, now: DateTime(2026, 9, 10));
  });
}
