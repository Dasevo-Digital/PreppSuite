import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/phrasebook/application/phrasebook.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_catalogue.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_providers.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_store.dart';
import 'package:preppsuite_flutter/features/translator/presentation/translator_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

const _de = PhraseLanguage.de;
const _en = PhraseLanguage.en;
const _fr = PhraseLanguage.fr;

InstalledTranslatorPack _installed(TranslatorDirection direction) =>
    InstalledTranslatorPack(
      direction: direction,
      version: '1.0',
      size: 30 * 1024 * 1024,
      modelPath: '/models/${direction.code}/model.bin',
      lexPath: '/models/${direction.code}/lex.bin',
      vocabPath: '/models/${direction.code}/vocab.spm',
    );

TranslatorPack _offered(TranslatorDirection direction) => TranslatorPack(
  direction: direction,
  version: '1.0',
  files: [
    for (final kind in TranslatorFileKind.values)
      TranslatorFile(
        kind: kind,
        name: '${kind.name}.${direction.code}',
        size: 10 * 1024 * 1024,
        sha256: '0' * 64,
        url: Uri.parse('https://example.org/${direction.code}/${kind.name}'),
      ),
  ],
);

/// Keeps its packs in memory; an install adds the direction at once.
class _FakeStore extends TranslatorStore {
  _FakeStore(Iterable<TranslatorDirection> directions)
    : packs = [for (final d in directions) _installed(d)];

  final List<InstalledTranslatorPack> packs;
  final installs = <TranslatorDirection>[];

  @override
  Future<List<InstalledTranslatorPack>> installed() async => [...packs];

  @override
  Stream<TranslatorInstallProgress> install(TranslatorPack pack) async* {
    installs.add(pack.direction);
    yield TranslatorInstallProgress(received: pack.size, total: pack.size);
    packs.add(_installed(pack.direction));
  }

  @override
  Future<void> remove(TranslatorDirection direction) async =>
      packs.removeWhere((pack) => pack.direction == direction);
}

void main() {
  late _FakeStore store;
  late List<List<InstalledTranslatorPack>> calls;

  Future<void> pump(
    WidgetTester tester, {
    bool available = true,
    Iterable<TranslatorDirection> installed = const [],
    Iterable<TranslatorDirection> offered = const [],
    Locale locale = const Locale('de'),
  }) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    store = _FakeStore(installed);
    calls = [];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          translatorAvailableProvider.overrideWithValue(available),
          translatorStoreProvider.overrideWithValue(store),
          translatorCatalogueProvider.overrideWith(
            (ref) async =>
                TranslatorCatalogue({for (final d in offered) d: _offered(d)}),
          ),
          translateTextProvider.overrideWithValue((text, packs) async {
            calls.add(packs);
            return 'Please call an ambulance.';
          }),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TranslatorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a build without the library says so and nothing else', (
    tester,
  ) async {
    await pump(tester, available: false);

    expect(find.textContaining('nicht enthalten'), findsOneWidget);
    expect(find.text('Übersetzen'), findsNothing);
  });

  testWidgets('with the pack here, German goes to English on one model', (
    tester,
  ) async {
    await pump(tester, installed: [const TranslatorDirection(_de, _en)]);

    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.textContaining('fehlt ein Sprachpaket'), findsNothing);

    await tester.enterText(
      find.byType(TextField),
      'Bitte rufen Sie einen Krankenwagen.',
    );
    await tester.pump();
    await tester.tap(find.text('Übersetzen'));
    await tester.pumpAndSettle();

    expect(find.text('Please call an ambulance.'), findsOneWidget);
    expect(find.textContaining('Maschinell übersetzt'), findsOneWidget);
    expect(calls, hasLength(1));
    expect(calls.single.map((p) => p.direction.code), ['deen']);
  });

  testWidgets('nothing to translate, nothing to press', (tester) async {
    await pump(tester, installed: [const TranslatorDirection(_de, _en)]);

    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Übersetzen'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('swapping turns the answer into the next question', (
    tester,
  ) async {
    await pump(
      tester,
      installed: const [
        TranslatorDirection(_de, _en),
        TranslatorDirection(_en, _de),
      ],
    );
    await tester.enterText(find.byType(TextField), 'Hallo');
    await tester.pump();
    await tester.tap(find.text('Übersetzen'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sprachen tauschen'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Please call an ambulance.');
    await tester.tap(find.text('Übersetzen'));
    await tester.pumpAndSettle();
    expect(calls.last.map((p) => p.direction.code), ['ende']);
  });

  testWidgets('German to French goes by way of English: two packs to fetch', (
    tester,
  ) async {
    await pump(
      tester,
      offered: const [
        TranslatorDirection(_de, _en),
        TranslatorDirection(_en, _fr),
      ],
    );
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Français').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('fehlt ein Sprachpaket'), findsOneWidget);
    expect(find.textContaining('Deutsch → English'), findsOneWidget);
    expect(find.textContaining('English → Français'), findsOneWidget);
    expect(find.text('Laden'), findsNWidgets(2));

    await tester.tap(find.text('Laden').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laden'));
    await tester.pumpAndSettle();

    expect(store.installs.map((d) => d.code), ['deen', 'enfr']);
    expect(find.textContaining('fehlt ein Sprachpaket'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Hallo');
    await tester.pump();
    await tester.tap(find.text('Übersetzen'));
    await tester.pumpAndSettle();
    expect(calls.single.map((p) => p.direction.code), ['deen', 'enfr']);
  });

  testWidgets('a direction Mozilla does not offer is named, not offered', (
    tester,
  ) async {
    await pump(tester);

    expect(find.textContaining('derzeit kein Sprachpaket'), findsOneWidget);
    expect(find.text('Laden'), findsNothing);
  });

  testWidgets('an installed pack can be taken off the device again', (
    tester,
  ) async {
    await pump(tester, installed: [const TranslatorDirection(_de, _en)]);

    expect(find.textContaining('Auf diesem Gerät'), findsOneWidget);
    await tester.tap(find.byTooltip('Sprachpaket entfernen'));
    await tester.pumpAndSettle();

    expect(store.packs, isEmpty);
    expect(find.textContaining('fehlt ein Sprachpaket'), findsOneWidget);
  });

  testWidgets('the same language on both sides is pointed out', (
    tester,
  ) async {
    await pump(tester, installed: [const TranslatorDirection(_de, _en)]);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('dieselbe Sprache'), findsOneWidget);
  });

  testWidgets('an English reader starts with German as the other side', (
    tester,
  ) async {
    await pump(
      tester,
      locale: const Locale('en'),
      installed: [const TranslatorDirection(_en, _de)],
    );

    expect(find.text('Translator'), findsOneWidget);
    expect(find.textContaining('A language pack'), findsNothing);
  });

  testWidgets('is accessible', (tester) async {
    await pump(tester, installed: [const TranslatorDirection(_de, _en)]);
    // With text and a result, so every control is live and every text is
    // on screen.
    await tester.enterText(find.byType(TextField), 'Hallo');
    await tester.pump();
    await tester.tap(find.text('Übersetzen'));
    await tester.pumpAndSettle();
    await expectAccessible(tester);
  });
}
