import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_theme.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_seeder.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_providers.dart';
import 'package:preppsuite_flutter/features/energy/presentation/outage_screen.dart';
import 'package:preppsuite_flutter/features/first_aid/presentation/first_aid_screen.dart';
import 'package:preppsuite_flutter/features/home/presentation/home_shell.dart';
import 'package:preppsuite_flutter/features/home/presentation/preparedness_tools_screen.dart';
import 'package:preppsuite_flutter/features/home/presentation/readiness_screen.dart';
import 'package:preppsuite_flutter/features/household/presentation/emergency_cards_screen.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/rotation_screen.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/shopping_list_screen.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/household/presentation/household_overview_screen.dart';
import 'package:preppsuite_flutter/features/home/presentation/emergency_screen.dart';
import 'package:preppsuite_flutter/features/checklists/presentation/checklist_list_screen.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_list_screen.dart';
import 'package:preppsuite_flutter/features/knowledge/presentation/knowledge_screen.dart';
import 'package:preppsuite_flutter/features/settings/presentation/settings_screen.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/warning_list_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The main screens with a believable household in them, light and dark,
/// as a telephone and as a wide window: what a change to the look has to be
/// judged on, rendered rather than imagined.
///
///     PREPPSUITE_REVIEW=/some/folder flutter test test/screenshots/design_review_test.dart
///
/// Skipped unless asked for. Nothing here touches an installed app: the
/// database is in memory.
void main() {
  final out = Platform.environment['PREPPSUITE_REVIEW'];
  const householdId = 'h';
  const profile = HouseholdProfile(
    id: householdId,
    name: 'Familie Muster',
    countryCode: 'DE',
    regionKey: '03101',
    personCount: 4,
  );

  setUpAll(() async {
    if (out == null) return;
    final text = FontLoader('Noto Sans')
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    await text.load();
    final root = File(Platform.resolvedExecutable).parent.parent.parent.path;
    final candidates = [
      '$root/artifacts/material_fonts/MaterialIcons-Regular.otf',
      '$root/material_fonts/MaterialIcons-Regular.otf',
    ];
    var path = candidates.firstWhere(
      (c) => File(c).existsSync(),
      orElse: () => '',
    );
    if (path.isEmpty) {
      final which = Process.runSync('which', ['flutter']).stdout as String;
      path =
          '${File(which.trim()).resolveSymbolicLinksSync().replaceAll('/bin/flutter', '')}'
          '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
      );
    await icons.load();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AppDatabase> seeded(WidgetTester tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.runAsync(() async {
      await ChecklistSeeder(db).seed(householdId);
      final now = DateTime.now();
      DateTime day(int n) => DateTime(now.year, now.month, now.day + n);
      Future<void> item(
        String name,
        String category,
        double quantity,
        String unit,
        String place, {
        DateTime? expiry,
        double? min,
        double? kcal,
        String? group,
      }) => db.upsertInventoryItem(
        InventoryItemsCompanion.insert(
          clientId: name,
          householdId: householdId,
          name: name,
          category: category,
          quantity: quantity,
          unit: unit,
          storageLocation: place,
          expirationDate: Value(expiry),
          minQuantity: Value(min),
          calories: Value(kcal),
          foodGroup: Value(group),
          updatedAt: DateTime.utc(2026, 10, 1),
        ),
      );
      await item('Trinkwasser', 'water', 24, 'l', 'Keller', expiry: day(300));
      await item(
        'Haferflocken',
        'food',
        2,
        'kg',
        'Vorratsschrank',
        expiry: day(200),
        kcal: 370,
        min: 1,
      );
      await item(
        'Ravioli',
        'food',
        6,
        'kg',
        'Keller',
        expiry: day(12),
        kcal: 90,
      );
      await item(
        'Reis',
        'food',
        5,
        'kg',
        'Keller',
        expiry: day(400),
        kcal: 350,
      );
      await item(
        'Milch',
        'food',
        1,
        'l',
        'Kühlschrank',
        expiry: day(-1),
        min: 2,
        kcal: 64,
      );
      await item(
        'Honig',
        'food',
        0.5,
        'kg',
        'Küche',
        expiry: day(700),
        kcal: 300,
      );
      await item('Taschenlampe', 'tools', 2, 'Stück', 'Flur');
      await item('Batterien AA', 'tools', 4, 'Stück', 'Flur', min: 8);
      await item('Ibuprofen', 'medical', 20, 'Stück', 'Bad', expiry: day(25));
      await item(
        'Verbandkasten',
        'medical',
        1,
        'Stück',
        'Auto',
        expiry: day(90),
      );
      await item('Kurbelradio', 'tools', 1, 'Stück', 'Wohnzimmer');
      final items = await db.watchAllChecklistItems(householdId).first;
      var i = 0;
      for (final row in items) {
        if (i++ % 3 == 0) {
          await db.upsertChecklistItem(
            row.toCompanion(false).copyWith(isChecked: const Value(true)),
          );
        }
      }
      final soon = DateTime.now().toUtc();
      await db
          .into(db.warnings)
          .insertOnConflictUpdate(
            WarningsCompanion.insert(
              source: 'dwd',
              externalId: 'w1',
              countryCode: 'DE',
              regionKey: const Value('03101'),
              severity: 'severe',
              eventType: 'Sturmböen',
              headline: 'Amtliche Warnung vor Sturmböen',
              description: const Value(
                'Es treten Sturmböen mit Geschwindigkeiten um 70 km/h auf.',
              ),
              effective: soon,
              expires: Value(soon.add(const Duration(hours: 8))),
              sent: soon,
              updatedAt: soon,
            ),
          );
    });
    return db;
  }

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget home, {
    required Size size,
    double scale = 2,
    bool dark = false,
  }) async {
    final db = await seeded(tester);
    addTearDown(() => tester.runAsync(db.close));
    tester.view.physicalSize = size * scale;
    tester.view.devicePixelRatio = scale;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    // Styles the theme carries outside its text theme have to be told too;
    // a test draws anything without a loaded family as black bars.
    ThemeData themed(ThemeData base) {
      TextStyle? noto(TextStyle? style) =>
          style?.copyWith(fontFamily: 'Noto Sans');
      return base.copyWith(
        textTheme: base.textTheme.apply(fontFamily: 'Noto Sans'),
        primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Noto Sans'),
        appBarTheme: base.appBarTheme.copyWith(
          titleTextStyle: noto(base.appBarTheme.titleTextStyle),
        ),
        navigationBarTheme: base.navigationBarTheme.copyWith(
          labelTextStyle: WidgetStatePropertyAll(
            noto(base.navigationBarTheme.labelTextStyle?.resolve({})),
          ),
        ),
        navigationRailTheme: base.navigationRailTheme.copyWith(
          selectedLabelTextStyle: noto(
            base.navigationRailTheme.selectedLabelTextStyle,
          ),
          unselectedLabelTextStyle: noto(
            base.navigationRailTheme.unselectedLabelTextStyle,
          ),
        ),
        listTileTheme: base.listTileTheme.copyWith(
          titleTextStyle: noto(base.listTileTheme.titleTextStyle),
          subtitleTextStyle: noto(base.listTileTheme.subtitleTextStyle),
        ),
        tabBarTheme: base.tabBarTheme.copyWith(
          labelStyle: noto(base.tabBarTheme.labelStyle),
          unselectedLabelStyle: noto(base.tabBarTheme.unselectedLabelStyle),
        ),
        chipTheme: base.chipTheme.copyWith(
          labelStyle: noto(base.chipTheme.labelStyle),
        ),
        floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
          extendedTextStyle: noto(
            base.floatingActionButtonTheme.extendedTextStyle,
          ),
        ),
      );
    }

    // The test binding draws a shadow as a black outline unless told not to.
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          householdProfileProvider.overrideWith(() => _Fixed(profile)),
          installedFirstAidPackProvider.overrideWith(
            (ref) async => InstalledFirstAidPack.none,
          ),
          firstAidPackUrlProvider.overrideWith((ref) async => ''),
        ],
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: themed(dark ? appDarkTheme : appLightTheme),
            home: home,
          ),
        ),
      ),
    );
    for (var turn = 0; turn < 14; turn++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    // What the screen costs to keep on screen: elements, render objects and
    // the paint layers that need a surface of their own.
    var elements = 0;
    var renders = 0;
    var layers = 0;
    var rows = 0;
    void visit(Element element) {
      elements++;
      if (element.widget is ListTile || element.widget is ExpansionTile) {
        rows++;
      }
      if (element is RenderObjectElement) {
        renders++;
        final object = element.renderObject;
        if (object is RenderPhysicalShape ||
            object is RenderPhysicalModel ||
            object is RenderClipRRect ||
            object is RenderClipRect ||
            object is RenderClipPath ||
            object is RenderOpacity ||
            object is RenderBackdropFilter ||
            object is RenderShaderMask) {
          layers++;
        }
      }
      element.visitChildren(visit);
    }

    tester.binding.rootElement!.visitChildren(visit);
    File('$out/costs.tsv').writeAsStringSync(
      '$name\t$elements\t$renders\t$layers\t$rows\n',
      mode: FileMode.append,
    );

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: scale);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
    // Drops what the schedulers left pending; the review only wants images.
    debugDisableShadows = true;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    while (tester.takeException() != null) {}
  }

  const phone = Size(400, 860);
  const wide = Size(1280, 800);
  final skip = out == null;

  final screens = <String, Widget>{
    'shell': const HomeShell(profile: profile),
    'emergency': EmergencyScreen(profile: profile, onNavigate: (_) {}),
    'inventory': const InventoryListScreen(householdId: householdId),
    'checklists': const ChecklistListScreen(householdId: householdId),
    'warnings': const WarningListScreen(profile: profile),
    'knowledge': const KnowledgeScreen(),
    'household': const HouseholdOverviewScreen(profile: profile),
    'settings': const SettingsScreen(profile: profile),
    'tools': const PreparednessToolsScreen(householdId: householdId),
    'firstaid': const FirstAidScreen(),
    'rotation': const RotationScreen(householdId: householdId),
    'shopping': const ShoppingListScreen(householdId: householdId),
    'readiness': const ReadinessScreen(profile: profile),
    'emergencycards': const EmergencyCardsScreen(householdId: householdId),
    'outage': const OutageScreen(householdId: householdId),
  };
  for (final MapEntry(key: name, value: screen) in screens.entries) {
    testWidgets('$name phone', (tester) async {
      await shoot(tester, '$name-phone-light', screen, size: phone);
    }, skip: skip);
  }
  testWidgets('shell dark', (tester) async {
    await shoot(
      tester,
      'shell-phone-dark',
      screens['shell']!,
      size: phone,
      dark: true,
    );
  }, skip: skip);
  testWidgets('emergency dark', (tester) async {
    await shoot(
      tester,
      'emergency-phone-dark',
      screens['emergency']!,
      size: phone,
      dark: true,
    );
  }, skip: skip);
  testWidgets('shell wide', (tester) async {
    await shoot(
      tester,
      'shell-wide-light',
      screens['shell']!,
      size: wide,
      scale: 1.5,
    );
  }, skip: skip);
  testWidgets('shell wide dark', (tester) async {
    await shoot(
      tester,
      'shell-wide-dark',
      screens['shell']!,
      size: wide,
      scale: 1.5,
      dark: true,
    );
  }, skip: skip);
}

class _Fixed extends HouseholdProfileController {
  _Fixed(this.profile);

  final HouseholdProfile profile;

  @override
  Future<HouseholdProfile?> build() async => profile;
}
