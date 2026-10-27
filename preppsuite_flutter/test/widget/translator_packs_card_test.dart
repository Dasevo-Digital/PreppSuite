import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/tesseract_data.dart';
import 'package:preppsuite_flutter/features/phrasebook/application/phrasebook.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_catalogue.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_providers.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_store.dart';
import 'package:preppsuite_flutter/features/translator/presentation/translator_packs_card.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

class _Store extends TranslatorStore {
  _Store(this.packs);

  final List<InstalledTranslatorPack> packs;

  @override
  Future<List<InstalledTranslatorPack>> installed() async => [...packs];

  @override
  Future<void> remove(TranslatorDirection direction) async =>
      packs.removeWhere((pack) => pack.direction == direction);
}

/// Text recognition data on an Android device, in memory.
class _Data extends DownloadedTesseractData {
  _Data(this.present);

  final Set<String> present;

  @override
  Future<bool> has(TesseractLanguage language) async =>
      present.contains(language.code);

  @override
  Future<void> remove(TesseractLanguage language) async =>
      present.remove(language.code);
}

InstalledTranslatorPack _pack(PhraseLanguage from, PhraseLanguage to) =>
    InstalledTranslatorPack(
      direction: TranslatorDirection(from, to),
      version: '1.0',
      size: 20 * 1024 * 1024,
      modelPath: '/m',
      lexPath: '/l',
      vocabPath: '/v',
    );

/// The packs beside the map in "Offline und Speicher" (#192).
void main() {
  Future<_Store> show(
    WidgetTester tester, {
    bool available = true,
    List<InstalledTranslatorPack> packs = const [],
    TesseractData? data,
  }) async {
    final store = _Store([...packs]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          translatorAvailableProvider.overrideWithValue(available),
          translatorStoreProvider.overrideWithValue(store),
          tesseractDataProvider.overrideWithValue(data ?? _Data({})),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TranslatorPacksCard(l10n: AppLocalizations.of(context)!),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('what is on the device, with its size, can be removed', (
    tester,
  ) async {
    final store = await show(
      tester,
      packs: [
        _pack(PhraseLanguage.de, PhraseLanguage.en),
        _pack(PhraseLanguage.en, PhraseLanguage.de),
      ],
    );

    expect(find.textContaining('2 Richtungen'), findsOneWidget);
    expect(find.text('Deutsch → English'), findsOneWidget);
    // The version, so an update can be seen to have arrived (#220).
    expect(find.textContaining(' · Fassung 1.0'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Sprachpaket entfernen').first);
    await tester.pumpAndSettle();

    expect(store.packs, hasLength(1));
    expect(find.textContaining('1 Richtung'), findsOneWidget);
  });

  testWidgets('with nothing yet it says where packs come from', (
    tester,
  ) async {
    await show(tester);
    expect(find.textContaining('Noch keine geladen'), findsOneWidget);
    expect(find.text('Zum Übersetzer'), findsOneWidget);
  });

  testWidgets('a build without the translator says so', (tester) async {
    await show(tester, available: false);
    expect(find.textContaining('nicht enthalten'), findsOneWidget);
    expect(find.text('Zum Übersetzer'), findsNothing);
  });

  testWidgets('the text recognition data for photos is listed and can be '
      'removed (#205)', (tester) async {
    final data = _Data({'rus', 'ara'});
    await show(tester, data: data);

    expect(find.text('Texterkennung für Fotos'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.textContaining('Русский, العربية · '), findsOneWidget);

    await tester.tap(find.byTooltip('Sprachpaket entfernen').first);
    await tester.pumpAndSettle();

    expect(data.present, hasLength(1));
  });

  testWidgets('without such data there is no section for it', (tester) async {
    await show(tester);

    expect(find.text('Texterkennung für Fotos'), findsNothing);
  });

  testWidgets('all packs can be fetched from here too (#182)', (tester) async {
    await show(tester);

    expect(
      find.text('Alle Sprachpakete laden oder aktualisieren'),
      findsOneWidget,
    );
    expect(find.text('Zum Übersetzer'), findsOneWidget);
  });

  testWidgets('a build without the library offers nothing to fetch', (
    tester,
  ) async {
    await show(tester, available: false);

    expect(
      find.text('Alle Sprachpakete laden oder aktualisieren'),
      findsNothing,
    );
  });
}
