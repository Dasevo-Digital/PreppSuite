import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';
import 'package:preppsuite_flutter/features/knowledge/presentation/personal_documents_screen.dart';
import 'package:preppsuite_flutter/features/knowledge/presentation/document_deadline_dialog.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const store = PersonalDocumentStore();
  Future<PersonalDocument> seed() async {
    final d = (await store.add(
      location: '/test/Plan.md',
      label: 'Plan.md',
    )).single;
    await store.updateDeadline(
      d.id,
      validUntil: DateTime(2028, 1, 1),
      remindOn: DateTime(2027, 12, 1),
      reviewedOn: null,
      originalLocation: 'Ordner A',
    );
    return (await store.load()).single;
  }

  Future<void> show(WidgetTester tester, {double scale = 1}) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: PersonalDocumentsScreen(downloadsDirectory: () async => null),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Dokumentaktionen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fristen und Original'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'editing and marking reviewed persists without a fading controller error',
    (tester) async {
      final d = await seed();
      await show(tester);
      await tester.enterText(find.byType(TextField), '  Schrank B  ');
      await tester.tap(find.text('Heute geprüft'));
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      final saved = (await store.load()).single;
      expect(saved.id, d.id);
      expect(saved.originalLocation, 'Schrank B');
      final today = DateTime.now();
      expect(saved.reviewedOn, DateTime(today.year, today.month, today.day));
      expect(find.text('Original: Schrank B'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dates can be removed and cancelling leaves the original unchanged',
    (tester) async {
      await seed();
      await show(tester);
      await tester.tap(find.byTooltip('Gültig bis entfernen'));
      await tester.tap(find.byTooltip('Erinnern am entfernen'));
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect((await store.load()).single.validUntil, DateTime(2028, 1, 1));
      await tester.tap(find.byTooltip('Dokumentaktionen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fristen und Original'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Gültig bis entfernen'));
      await tester.tap(find.byTooltip('Erinnern am entfernen'));
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect((await store.load()).single.validUntil, isNull);
      expect((await store.load()).single.remindOn, isNull);
    },
  );

  testWidgets('the deadline form stays usable with large text', (tester) async {
    await seed();
    await show(tester, scale: 2);
    expect(find.byType(DocumentDeadlineDialog), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a calendar date chosen through the picker is saved as a date', (
    tester,
  ) async {
    await seed();
    await show(tester);
    await tester.tap(find.text('Gültig bis'));
    await tester.pumpAndSettle();
    final material = MaterialLocalizations.of(
      tester.element(find.byType(DatePickerDialog)),
    );
    await tester.tap(find.byTooltip(material.inputDateModeButtonLabel));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '31.12.2028');
    await tester.tap(find.text(material.okButtonLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect((await store.load()).single.validUntil, DateTime(2028, 12, 31));
  });

  testWidgets('a reminder after expiry is explained and cannot be saved', (
    tester,
  ) async {
    final d = await seed();
    await store.updateDeadline(
      d.id,
      validUntil: DateTime(2027),
      remindOn: DateTime(2028),
      reviewedOn: null,
      originalLocation: 'A',
    );
    await show(tester);
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(
      find.text('Die Erinnerung muss vor oder am Gültigkeitsende liegen.'),
      findsOneWidget,
    );
    expect(find.byType(DocumentDeadlineDialog), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'due filtering includes expired documents and hides current ones',
    (tester) async {
      final d = await seed();
      await store.updateDeadline(
        d.id,
        validUntil: DateTime(2020),
        remindOn: null,
        reviewedOn: null,
        originalLocation: '',
      );
      await store.add(location: '/test/Other.md', label: 'Other.md');
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PersonalDocumentsScreen(downloadsDirectory: () async => null),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fällige Fristen: 1'));
      await tester.pumpAndSettle();
      expect(find.text('Plan.md'), findsOneWidget);
      expect(find.text('Other.md'), findsNothing);
    },
  );
}
