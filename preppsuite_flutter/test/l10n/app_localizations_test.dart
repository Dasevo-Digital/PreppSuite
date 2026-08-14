import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations_de.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations_en.dart';

void main() {
  // Static gen-l10n already validates ARB structure at generate time and a
  // separate key-parity check (109/109 keys, both directions) covers the
  // plain getters. What that doesn't cover is runtime interpolation
  // behavior for the placeholder/plural strings — the one place a
  // locale-specific formatting quirk could still slip through.
  group('parameterized strings resolve correctly for both locales', () {
    for (final AppLocalizations l10n in [
      AppLocalizationsDe(),
      AppLocalizationsEn(),
    ]) {
      final locale = l10n.localeName;

      test('[$locale] errorGeneric interpolates the error text', () {
        final result = l10n.errorGeneric('boom');
        expect(result, isNotEmpty);
        expect(result, contains('boom'));
      });

      test('[$locale] scannedBarcodeLabel interpolates the barcode', () {
        final result = l10n.scannedBarcodeLabel('4006381333931');
        expect(result, isNotEmpty);
        expect(result, contains('4006381333931'));
      });

      test('[$locale] checklistProgress interpolates both counts', () {
        final result = l10n.checklistProgress(2, 5);
        expect(result, isNotEmpty);
        expect(result, contains('2'));
        expect(result, contains('5'));
      });

      test('[$locale] warningBannerMore interpolates the count', () {
        final result = l10n.warningBannerMore(3);
        expect(result, isNotEmpty);
        expect(result, contains('3'));
      });

      test('[$locale] pdfGeneratedOn interpolates the date text', () {
        final result = l10n.pdfGeneratedOn('1. Januar 2026');
        expect(result, isNotEmpty);
        expect(result, contains('1. Januar 2026'));
      });
    }
  });

  test(
    'both locales are registered and resolvable via lookupAppLocalizations',
    () {
      expect(
        lookupAppLocalizations(const Locale('de')),
        isA<AppLocalizationsDe>(),
      );
      expect(
        lookupAppLocalizations(const Locale('en')),
        isA<AppLocalizationsEn>(),
      );
    },
  );
}
