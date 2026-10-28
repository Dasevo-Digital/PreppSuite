import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/application/offline_probe.dart';
import 'package:preppsuite_flutter/features/home/presentation/offline_probe_card.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    OfflineProbe probe, {
    Locale locale = const Locale('de'),
    double scale = 1,
  }) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: ListView(children: [OfflineProbeCard(probe: probe)]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a read test is not presented as a disconnected offline test', (
    tester,
  ) async {
    await show(
      tester,
      OfflineProbe(
        targets: () async => [
          OfflineProbeTarget(
            OfflineProbeKind.document,
            'Plan.md',
            (_) async {},
          ),
          OfflineProbeTarget(OfflineProbeKind.archive, 'Broken', (_) async {
            throw const FormatException('private details');
          }),
        ],
      ),
    );
    await tester.tap(find.text('Lesetest starten'));
    await tester.pumpAndSettle();
    expect(
      find.text('1 lesbar · 1 fehlgeschlagen · 0 nicht geprüft'),
      findsOneWidget,
    );
    expect(find.textContaining('Lesetest ·'), findsOneWidget);
    expect(find.textContaining('private details'), findsNothing);
    expect(find.text('Stichprobe erfolgreich gelesen'), findsOneWidget);
  });

  testWidgets(
    'the reported mode is captured at start and cancellation is visible',
    (tester) async {
      final pending = Completer<void>();
      await show(
        tester,
        OfflineProbe(
          targets: () async => [
            OfflineProbeTarget(
              OfflineProbeKind.document,
              'Plan.md',
              (_) => pending.future,
            ),
          ],
        ),
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Offline-Probelauf starten'));
      await tester.pump();
      await tester.tap(find.text('Prüfung abbrechen'));
      await tester.pump();
      expect(find.text('Prüfung wird beendet …'), findsOneWidget);
      pending.complete();
      await tester.pumpAndSettle();
      expect(
        find.text('0 lesbar · 0 fehlgeschlagen · 1 nicht geprüft'),
        findsOneWidget,
      );
      expect(find.textContaining('Offline-Probelauf ·'), findsOneWidget);
    },
  );

  for (final locale in ['de', 'en', 'es']) {
    testWidgets('the probe is readable at large text in $locale', (
      tester,
    ) async {
      await show(
        tester,
        OfflineProbe(targets: () async => []),
        locale: Locale(locale),
        scale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
