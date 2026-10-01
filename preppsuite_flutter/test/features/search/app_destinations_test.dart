import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_destinations.dart';
import 'package:preppsuite_flutter/features/home/application/shell_layout.dart';
import 'package:preppsuite_flutter/features/search/application/app_search.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations_de.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations_en.dart';

/// The list that says what the app can do.
///
/// Its whole value is being complete. A screen that exists and is not in
/// it is a screen the search cannot find, and nobody notices that by
/// using the app — they notice it by failing to find something and
/// concluding the app cannot do it.
void main() {
  final destinations = appDestinations();
  final AppLocalizations de = AppLocalizationsDe();
  final AppLocalizations en = AppLocalizationsEn();

  test('every id is its own', () {
    // Ids are what the tests below and any future bookmark name. Two the
    // same means one of them can never be addressed.
    final ids = destinations.map((d) => d.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('every tab is reachable, exactly once', () {
    final tabs = [
      for (final d in destinations)
        if (d.isTab) d.area,
    ];

    expect(tabs.toSet(), ShellDestination.values.toSet());
    expect(tabs, hasLength(ShellDestination.values.length));
  });

  test('every destination is named in both languages', () {
    for (final destination in destinations) {
      expect(destination.title(de), isNotEmpty, reason: destination.id);
      expect(destination.title(en), isNotEmpty, reason: destination.id);
    }
  });

  test('aliases are already folded, so matching does not have to guess', () {
    // They are never displayed, so there is no reason for them to carry
    // capitals or umlauts — and every reason for them to be stored the
    // way they will be compared.
    for (final destination in destinations) {
      for (final alias in destination.aliases) {
        expect(
          alias,
          foldForSearch(alias),
          reason: '${destination.id}: $alias',
        );
      }
    }
  });

  test('a pushed destination builds and a tab does not', () {
    for (final destination in destinations) {
      expect(
        destination.open == null,
        destination.isTab,
        reason: destination.id,
      );
    }
  });

  group('staying in step with the screens', () {
    /// Screens that are deliberately not destinations, with the reason.
    ///
    /// Every one of them needs something that does not exist until
    /// somebody has chosen it: a row to edit, an archive to read from, a
    /// camera, a photograph. They are reached from the thing they are
    /// about, which is the only place they mean anything.
    const notDestinations = {
      // Forms, reached from the record they edit.
      'BudgetEntryFormScreen',
      'ChecklistDetailScreen',
      'EmergencyCardFormScreen',
      'InventoryItemFormScreen',
      'PossessionFormScreen',
      // Need a document, an archive or a file.
      'ArticleReaderScreen',
      'ArticleScreen',
      'FirstAidGuideScreen',
      // One chapter of the comic, and its summary sheet: pages of a story
      // that is itself a destination, read in order from its cover.
      'KidsComicChapterScreen',
      'KidsComicRulesScreen',
      'FirstAidVideoScreen',
      'PersonalDocumentReaderScreen',
      'PhotoEditorScreen',
      'PersonalPlacesScreen',
      // Needs a camera.
      'BarcodeScannerScreen',
      // Setup, before there is a household to search in.
      'ProfileSetupScreen',
      'SetupChoiceScreen',
      // Itself. A result that takes you to where you already are is a
      // result nobody wanted.
      'AppSearchScreen',
      // The tabs themselves, which are destinations under another name.
      'OverviewScreen',
      'EmergencyScreen',
      'InventoryListScreen',
      'ChecklistListScreen',
      'WarningListScreen',
      'ShelterMapScreen',
      'MapScreen',
      'KnowledgeScreen',
      'HouseholdOverviewScreen',
      'SettingsScreen',
      // Budget is reached from the household overview and has no
      // searchable records of its own yet.
      'BudgetListScreen',
      // The CSV import belongs to the inventory's own menu: it acts on
      // the list it is opened from.
      'InventoryCsvImportScreen',
    };

    test('every screen is either a destination or excused by name', () {
      final registered = <String>{};
      final source = File('lib/core/app_destinations.dart').readAsStringSync();
      for (final match in RegExp(r'\b(\w+Screen)\b').allMatches(source)) {
        registered.add(match.group(1)!);
      }

      final missing = <String>[];
      for (final file
          in Directory('lib/features')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('_screen.dart'))) {
        final name = RegExp(
          r'^class (\w+Screen)\b',
          multiLine: true,
        ).firstMatch(file.readAsStringSync())?.group(1);
        if (name == null) continue;
        if (registered.contains(name)) continue;
        if (notDestinations.contains(name)) continue;
        missing.add(name);
      }

      expect(
        missing,
        isEmpty,
        reason:
            'These screens cannot be found by searching. Add them to '
            'app_destinations.dart, or to notDestinations above with the '
            'reason they are reached some other way.',
      );
    });

    test('and nothing is excused that no longer exists', () {
      // An excuse left behind after a screen is deleted is an excuse
      // that will quietly cover the next screen to take its name.
      final present = <String>{};
      for (final file
          in Directory('lib/features')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('_screen.dart'))) {
        final name = RegExp(
          r'^class (\w+Screen)\b',
          multiLine: true,
        ).firstMatch(file.readAsStringSync())?.group(1);
        if (name != null) present.add(name);
      }

      expect(notDestinations.difference(present), isEmpty);
    });
  });
}
