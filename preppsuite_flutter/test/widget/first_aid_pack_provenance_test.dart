import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_video_pack.dart';
import 'package:preppsuite_flutter/features/first_aid/presentation/first_aid_videos_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

/// Where a pack comes from, and whether anybody checked it (#58).
void main() {
  const video = FirstAidVideo(
    id: 'cpr-1',
    guideId: 'cpr-adult',
    title: 'Herzdruckmassage',
    fileName: 'cpr.mp4',
    credit: 'Jemand',
    licence: 'CC BY 4.0',
  );

  Future<AppLocalizations> show(
    WidgetTester tester,
    FirstAidVideoPack pack,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PackProvenance(pack: pack)),
      ),
    );
    return AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
  }

  testWidgets('a pack that names no reviewer is said to name none', (
    tester,
  ) async {
    final l10n = await show(
      tester,
      const FirstAidVideoPack(name: 'Videos', language: 'de', videos: [video]),
    );

    expect(
      find.text(
        l10n.firstAidVideoPackPublisher(l10n.firstAidVideoPackNotStated),
      ),
      findsOneWidget,
    );
    expect(find.text(l10n.firstAidVideoPackNotReviewed), findsOneWidget);
  });

  testWidgets('one that does says who, as the pack states it', (tester) async {
    final l10n = await show(
      tester,
      const FirstAidVideoPack(
        name: 'Videos',
        language: 'de',
        videos: [video],
        publisher: 'Ortsverein Musterstadt',
        reviewedBy: 'Notfallsanitäterin, Oktober 2026',
        about: 'Eigene Aufnahmen.',
      ),
    );

    expect(
      find.text(l10n.firstAidVideoPackPublisher('Ortsverein Musterstadt')),
      findsOneWidget,
    );
    expect(
      find.text(
        l10n.firstAidVideoPackReviewed('Notfallsanitäterin, Oktober 2026'),
      ),
      findsOneWidget,
    );
    expect(find.text('Eigene Aufnahmen.'), findsOneWidget);
  });
}
