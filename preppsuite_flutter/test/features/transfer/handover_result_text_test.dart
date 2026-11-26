import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/carried_settings.dart';
import 'package:preppsuite_flutter/features/transfer/presentation/handover_result_text.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

/// What each side of a local handover says once it is over (#399).
///
/// The host of a device being set up sends the whole household and takes
/// in nothing, and it said that both devices had already been at the same
/// point. Neither side knows what the other took in, so neither says.
void main() {
  late Map<String, AppLocalizations> languages;

  setUpAll(() async {
    languages = {
      for (final code in ['de', 'en', 'es'])
        code: await AppLocalizations.delegate.load(Locale(code)),
    };
  });

  test('a side that took in nothing says so of itself alone', () {
    // The host after a guest was set up from it: everything went out.
    const result = (
      received: 0,
      sent: 412,
      photos: 0,
      household: CarriedHousehold(),
    );

    final said = {
      for (final MapEntry(:key, :value) in languages.entries)
        key: handoverResultText(value, result),
    };

    expect(said['de'], 'Abgeglichen. Auf diesem Gerät kam nichts Neues an.');
    expect(said['de'], isNot(contains('Beide')));
    expect(said['en'], isNot(contains('Both')));
    expect(said['es'], isNot(contains('Los dos')));
  });

  test('what arrived here, pictures included, on either side', () {
    final de = languages['de']!;
    const result = (
      received: 7,
      sent: 0,
      photos: 2,
      household: CarriedHousehold(),
    );

    expect(
      handoverResultText(de, result),
      '${de.transferHandoverDone(7)} ${de.transferHandoverPhotos(2)}',
    );
  });
}
