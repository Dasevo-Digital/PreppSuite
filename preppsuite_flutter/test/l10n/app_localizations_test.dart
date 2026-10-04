import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations_de.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations_en.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations_es.dart';

void main() {
  // Static gen-l10n already validates ARB structure at generate time and a
  // separate key-parity check (109/109 keys, both directions) covers the
  // plain getters. What that doesn't cover is runtime interpolation
  // behavior for the placeholder/plural strings — the one place a
  // locale-specific formatting quirk could still slip through.
  group('parameterized strings resolve correctly for every locale', () {
    for (final AppLocalizations l10n in [
      AppLocalizationsDe(),
      AppLocalizationsEn(),
      AppLocalizationsEs(),
    ]) {
      final locale = l10n.localeName;

      test('[$locale] errorGeneric is safe generic copy', () {
        final result = l10n.errorGeneric;
        expect(result, isNotEmpty);
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
      expect(
        lookupAppLocalizations(const Locale('es')),
        isA<AppLocalizationsEs>(),
      );
    },
  );

  /// Every language has every string, with the same placeholders and the
  /// same plural cases (#104). gen-l10n falls back to the template for a
  /// missing key without a word, so a Spanish screen would quietly show
  /// English -- and a placeholder dropped in translation would show the
  /// sentence without its number.
  group('the three ARB files agree', () {
    Map<String, String> strings(String code) {
      final decoded =
          jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
              as Map<String, dynamic>;
      return {
        for (final MapEntry(:key, :value) in decoded.entries)
          if (!key.startsWith('@')) key: value as String,
      };
    }

    // `{name}` or `{name, plural, …}` -- not any word before a comma,
    // which a plural case like `=0{Stromausfall, gerade begonnen}` has.
    final placeholder = RegExp(
      r'\{(\w+)(?=\}|\s*,\s*(?:plural|select|number|date|time)\b)',
    );
    final pluralCase = RegExp(r'(=\d+|zero|one|two|few|many|other)\{');
    Set<String> names(String text) =>
        placeholder.allMatches(text).map((m) => m[1]!).toSet();
    List<String> cases(String text) =>
        pluralCase.allMatches(text).map((m) => m[1]!).toList()..sort();

    final en = strings('en');
    for (final code in ['de', 'es']) {
      test('[$code] has exactly the keys of the template', () {
        expect(strings(code).keys.toSet(), en.keys.toSet());
      });

      test('[$code] keeps every placeholder and plural case', () {
        final other = strings(code);
        final mismatches = [
          for (final key in en.keys)
            if (other[key] case final text?)
              if (!_sameSet(names(en[key]!), names(text)) ||
                  cases(en[key]!).join() != cases(text).join())
                key,
        ];
        expect(mismatches, isEmpty);
      });
    }
  });
}

bool _sameSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
