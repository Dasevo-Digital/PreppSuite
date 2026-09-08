import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_providers.dart';
import 'package:preppsuite_flutter/features/home/presentation/overview_screen.dart';
import 'package:preppsuite_flutter/features/home/presentation/home_shell.dart';
import 'package:preppsuite_flutter/features/maps/presentation/map_screen.dart';
import 'package:preppsuite_flutter/features/shelters/presentation/shelter_map_screen.dart';
import 'package:preppsuite_flutter/features/knowledge/presentation/knowledge_screen.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_list_screen.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_filter_sheet.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const imageDir = String.fromEnvironment('REVIEW_IMAGE_DIR');
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'overview and inventory ${size.width} dark=$dark scale=$scale',
          (tester) async {
            SharedPreferences.setMockInitialValues({});
            final db = AppDatabase.forTesting(NativeDatabase.memory());
            addTearDown(db.close);
            await tester.binding.setSurfaceSize(size);
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final font = FontLoader('NotoSans')
              ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
            await tester.runAsync(font.load);
            final icons = FontLoader('MaterialIcons')
              ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
            await tester.runAsync(icons.load);
            final boundary = GlobalKey();
            final items = [
              InventoryItem(
                clientId: 'a',
                householdId: 'h',
                name: 'Trinkwasser',
                category: 'water',
                quantity: 12.5,
                unit: 'L',
                storageLocation: 'Keller',
                minQuantity: 40,
                updatedAt: DateTime(2026),
                dirty: false,
              ),
              InventoryItem(
                clientId: 'b',
                householdId: 'h',
                name: 'Haferflocken',
                category: 'food',
                quantity: 4,
                unit: 'Packungen',
                storageLocation: 'Vorratsschrank',
                calories: 1750,
                updatedAt: DateTime(2026),
                dirty: false,
              ),
            ];
            Future<void> render(Widget screen, {bool empty = false}) async {
              await tester.pumpWidget(
                ProviderScope(
                  key: UniqueKey(),
                  overrides: [
                    appDatabaseProvider.overrideWithValue(db),
                    inventoryItemsProvider(
                      'h',
                    ).overrideWith((ref) => Stream.value(empty ? [] : items)),
                    activeWarningsProvider.overrideWith(
                      (ref) => Stream.value([]),
                    ),
                    checklistTemplatesProvider(
                      'h',
                    ).overrideWith((ref) => Stream.value([])),
                    allChecklistItemsProvider(
                      'h',
                    ).overrideWith((ref) => Stream.value([])),
                  ],
                  child: RepaintBoundary(
                    key: boundary,
                    child: MaterialApp(
                      debugShowCheckedModeBanner: false,
                      locale: const Locale('de'),
                      localizationsDelegates:
                          AppLocalizations.localizationsDelegates,
                      supportedLocales: AppLocalizations.supportedLocales,
                      theme: ThemeData(
                        colorSchemeSeed: const Color(0xFF2E7D32),
                        brightness: dark ? Brightness.dark : Brightness.light,
                        fontFamily: 'NotoSans',
                      ),
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(textScaler: TextScaler.linear(scale)),
                        child: child!,
                      ),
                      home: screen,
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }

            Future<void> capture(String name) async {
              if (imageDir.isEmpty || scale != 1) return;
              await tester.runAsync(() async {
                final image =
                    await (boundary.currentContext!.findRenderObject()!
                            as RenderRepaintBoundary)
                        .toImage();
                final bytes = (await image.toByteData(
                  format: ui.ImageByteFormat.png,
                ))!.buffer.asUint8List();
                await Directory(imageDir).create(recursive: true);
                await File(
                  '$imageDir/$name-${size.width.toInt()}-${dark ? 'dark' : 'light'}.png',
                ).writeAsBytes(bytes);
                image.dispose();
              });
            }

            Widget overview() => OverviewScreen(
              profile: const HouseholdProfile(
                id: 'h',
                name: 'Zuhause',
                countryCode: 'DE',
                personCount: 2,
              ),
              onNavigate: (_) {},
            );
            if (size.width == 390 && !dark && scale == 1) {
              await render(
                const HomeShell(
                  profile: HouseholdProfile(
                    id: 'h',
                    name: 'Zuhause',
                    countryCode: 'DE',
                  ),
                ),
              );
              expect(find.byType(MapScreen, skipOffstage: false), findsNothing);
              expect(
                find.byType(ShelterMapScreen, skipOffstage: false),
                findsNothing,
              );
              expect(
                find.byType(KnowledgeScreen, skipOffstage: false),
                findsNothing,
              );
            }
            await render(overview(), empty: true);
            expect(
              find.text(
                AppLocalizations.of(
                  tester.element(find.byType(OverviewScreen)),
                )!.overviewAddFirst,
              ),
              findsOneWidget,
            );
            await capture('overview-empty');
            await render(overview());
            await capture('overview');
            await render(const InventoryListScreen(householdId: 'h'));
            await capture('inventory');
            final search = find.byType(TextField).first;
            await tester.ensureVisible(search);
            await tester.enterText(search, 'Hafer');
            await tester.pumpAndSettle();
            expect(find.widgetWithText(ListTile, 'Trinkwasser'), findsNothing);
            await tester.tap(find.byIcon(Icons.clear));
            await tester.pumpAndSettle();
            await tester.tap(find.byIcon(Icons.filter_alt_outlined));
            await tester.pumpAndSettle();
            expect(find.byType(InventoryFilterSheet), findsOneWidget);
            expect(tester.takeException(), isNull);
            await capture('inventory-filters');
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }
}
