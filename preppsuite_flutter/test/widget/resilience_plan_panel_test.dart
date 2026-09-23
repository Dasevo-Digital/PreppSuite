import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/preparedness/application/resilience_plan.dart';
import 'package:preppsuite_flutter/features/preparedness/presentation/resilience_plan_panel.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('shows local warning, learning, source and neighbourhood plans', (
    tester,
  ) async {
    final checkedAt = DateTime(2026, 9, 23);
    var plan = ResiliencePlan(
      warningChecks: {'radio': checkedAt},
      sources: [
        TrustedSource(
          id: 'source',
          label: 'Gemeinde',
          channel: 'Amtliche Website',
          offlineFallback: 'Radio',
          checkedAt: checkedAt,
        ),
      ],
      neighborhood: [
        NeighborhoodCapability(
          id: 'helper',
          alias: 'Funkhilfe',
          skill: 'Kurbelradio',
          contactMethod: 'Treffpunkt',
          meetingPoint: 'Aushang',
          checkedAt: checkedAt,
        ),
      ],
      maintenanceEveryDays: {'radio': 30},
    );

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResiliencePlanPanel(
                plan: plan,
                maintenance: {'radio': DateTime(2026, 8, 1)},
                onPlanChanged: (next) => setState(() => plan = next),
                onMaintenanceIntervalChanged: (task, days) => setState(
                  () => plan = plan.copyWith(
                    maintenanceEveryDays: {
                      ...plan.maintenanceEveryDays,
                      task: days,
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Warnwege prüfen'), findsOneWidget);
    expect(find.text('Persönliche Unterstützung'), findsOneWidget);
    expect(find.text('Quellen-Kompass'), findsOneWidget);
    expect(find.text('APOLLO-Lernpfade'), findsOneWidget);
    expect(find.text('Nachbarschaftshilfe'), findsOneWidget);
    expect(find.text('Gemeinde'), findsOneWidget);
    expect(find.text('Funkhilfe'), findsOneWidget);
    expect(find.text('Prüfung fällig'), findsOneWidget);

    await tester.tap(find.text('Cell Broadcast am Gerät geprüft'));
    await tester.pump();

    expect(plan.warningChecks, contains('cell'));
  });
}
