import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/built_in_templates.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_providers.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_seeder.dart';
import 'package:preppsuite_flutter/features/checklists/presentation/checklist_list_screen.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The checklists, split by what they are for.
///
/// "What should I have" and "what do I do now" are asked at different
/// moments, and the answer to one should not be something to scroll past
/// to reach the other.
///
/// The rows are built straight from the built-in declaration rather than
/// read out of a database, which is also what makes this a test of the
/// declaration: a list filed on the wrong side of the split shows up
/// under the wrong tab here.
void main() {
  const householdId = 'h';

  setUp(() => SharedPreferences.setMockInitialValues({}));

  final templates = [
    for (final template in builtInTemplates)
      ChecklistTemplate(
        clientId: template.clientId,
        householdId: householdId,
        title: template.title,
        category: template.category.name,
        kind: template.kind.name,
        isBuiltIn: true,
        updatedAt: ChecklistSeeder.seededAt,
        dirty: false,
      ),
  ];

  late AppLocalizations l10n;

  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checklistTemplatesProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(templates)),
          checklistItemsProvider.overrideWith(
            (ref, String templateId) => Stream.value(const []),
          ),
          inventoryItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ChecklistListScreen(householdId: householdId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    l10n = AppLocalizations.of(
      tester.element(find.byType(ChecklistListScreen)),
    )!;
  }

  testWidgets('there are two tabs and preparation is the one in front', (
    tester,
  ) async {
    await open(tester);

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text(l10n.checklistKindPreparation), findsOneWidget);
    expect(find.text(l10n.checklistKindResponse), findsOneWidget);
    // The sentence under the heading: two words on a tab are not enough
    // to say which of the two somebody is looking at.
    expect(find.text(l10n.checklistKindPreparationIntro), findsOneWidget);
  });

  testWidgets('stocking lists are under preparation', (tester) async {
    await open(tester);

    // Twice: the list is called "Wasser" and so is its heading.
    expect(find.text('Wasser'), findsNWidgets(2));
    expect(find.text('Lebensmittel'), findsOneWidget);
    expect(find.text('Notgepäck'), findsNWidgets(2));
    // Named for an event, and still a list of what to buy for it.
    expect(find.text('Strom- und Heizungsausfall'), findsOneWidget);
    expect(find.text('Wenn der Strom ausfällt'), findsNothing);
  });

  testWidgets('and the acting lists are behind the other tab', (tester) async {
    await open(tester);

    await tester.tap(find.text(l10n.checklistKindResponse));
    await tester.pumpAndSettle();

    expect(find.text(l10n.checklistKindResponseIntro), findsOneWidget);
    expect(find.text('Wenn der Strom ausfällt'), findsOneWidget);
    expect(find.text('Schutz suchen'), findsOneWidget);
    // The one about what to buy stays on the other side.
    expect(find.text('Wasser'), findsNothing);
    expect(find.text('Strom- und Heizungsausfall'), findsNothing);
  });

  testWidgets('the category headings survive inside each tab', (tester) async {
    // The split is a second axis, not a replacement: with nineteen lists
    // one heading each way is still a wall.
    await open(tester);

    expect(find.text(l10n.categoryFood), findsOneWidget);
    expect(find.text(l10n.categoryEnergy), findsOneWidget);
    expect(find.text(l10n.categoryHygiene), findsNWidgets(2));
  });
}
