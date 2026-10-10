import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/storage_plan.dart';
import 'package:preppsuite_flutter/features/inventory/application/storage_plan_es.dart';
import 'package:preppsuite_flutter/features/inventory/application/storage_plan_l10n.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The BLE tables in Spanish (#108).
///
/// The Spanish words sit in a map keyed by the German text, beside a
/// transcription that knows nothing of them. What holds the two together
/// is this file: every German name, remark and footnote has a Spanish
/// one, and nothing in the map names a row that no longer exists.
void main() {
  /// Every German text the two tables carry.
  Set<String> germanTexts() => {
    for (final diet in StorageDiet.values)
      for (final group in storagePlanFor(diet).groups) ...[
        group.name,
        ?group.footnote,
        for (final food in group.foods) ...[
          food.name,
          ?food.note,
          for (final variant in food.variants) variant.name,
        ],
      ],
  };

  test('every text in the tables has a Spanish one', () {
    final missing = germanTexts().difference(storagePlanSpanish.keys.toSet());
    expect(missing, isEmpty);
  });

  test('and the Spanish list names nothing the tables do not', () {
    final stale = storagePlanSpanish.keys.toSet().difference(germanTexts());
    expect(stale, isEmpty);
  });

  test('no Spanish text is empty', () {
    for (final MapEntry(:key, :value) in storagePlanSpanish.entries) {
      expect(value.trim(), isNotEmpty, reason: key);
    }
  });

  test('a Spanish reader gets Spanish, the others what they had', () {
    final group = storagePlanFor(StorageDiet.mixed).groups.first;
    final food = group.foods.first;
    String nameIn(String locale) =>
        storageFoodName(lookupAppLocalizations(Locale(locale)), food);

    expect(nameIn('de'), food.name);
    expect(nameIn('en'), food.nameEn);
    expect(nameIn('es'), storagePlanSpanish[food.name]);
    expect(
      storageGroupName(lookupAppLocalizations(const Locale('es')), group),
      'Cereales, pan, patatas',
    );
  });
}
