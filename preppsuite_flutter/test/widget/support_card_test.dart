import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/settings/presentation/support_card.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    Future<bool> Function(Uri uri) launch,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SupportCard(launch: launch)),
      ),
    );
  }

  testWidgets('names the address and opens exactly that page', (
    tester,
  ) async {
    final opened = <Uri>[];
    await pumpCard(tester, (uri) async {
      opened.add(uri);
      return true;
    });

    expect(find.text('PreppSuite unterstützen'), findsOneWidget);
    // The literal, not SupportCard.address: a changed link should make
    // this test say so.
    await tester.tap(find.text('ko-fi.com/superkuh86'));
    await tester.pump();

    expect(opened, [Uri.parse('https://ko-fi.com/superkuh86')]);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('says where the page is when no browser opens', (tester) async {
    await pumpCard(tester, (uri) async => throw StateError('no browser'));

    await tester.tap(find.text('ko-fi.com/superkuh86'));
    await tester.pump();

    expect(
      find.text(
        'Der Browser ließ sich nicht öffnen. '
        'Die Adresse lautet ko-fi.com/superkuh86.',
      ),
      findsOneWidget,
    );
  });
}
