import 'dart:async';

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

InstalledTranslatorPack _installed(
  TranslatorDirection direction, {
  String version = '1.0',
}) => InstalledTranslatorPack(
  direction: direction,
  version: version,
  size: 30 * 1024 * 1024,
  modelPath: '/models/${direction.code}/model.bin',
  lexPath: '/models/${direction.code}/lex.bin',
  vocabPath: '/models/${direction.code}/vocab.spm',
);

TranslatorPack _offered(
  TranslatorDirection direction, {
  String version = '1.0',
}) => TranslatorPack(
  direction: direction,
  version: version,
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
    packs
      ..removeWhere((each) => each.direction == pack.direction)
      ..add(_installed(pack.direction, version: pack.version));
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
    Map<TranslatorDirection, String> versions = const {},
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
            (ref) async => TranslatorCatalogue({
              for (final d in offered)
                d: _offered(d, version: versions[d] ?? '1.0'),
            }),
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

  testWidgets('the result can be held up large (#189)', (tester) async {
    await pump(tester, installed: [const TranslatorDirection(_de, _en)]);
    await tester.enterText(find.byType(TextField), 'Hilfe');
    await tester.pump();
    await tester.tap(find.text('Übersetzen'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Groß zeigen'));
    await tester.pumpAndSettle();
    final large = tester.widget<Text>(
      find.text('Please call an ambulance.').last,
    );
    expect(large.style?.fontSize, greaterThan(30));
    // What was typed, small underneath, so the holder knows what it says.
    expect(find.text('Hilfe'), findsWidgets);
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

  group('all language packs at once (#182)', () {
    const enFr = TranslatorDirection(_en, _fr);
    const frEn = TranslatorDirection(_fr, _en);
    const deEn = TranslatorDirection(_de, _en);
    const enDe = TranslatorDirection(_en, _de);

    testWidgets('says how many and how much, then fetches them in turn', (
      tester,
    ) async {
      await pump(
        tester,
        installed: [deEn],
        offered: [enFr, frEn, deEn, enDe],
      );

      final button = find.text('Alle Sprachpakete laden oder aktualisieren');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Three packs are missing; the one here is not counted.
      expect(find.textContaining('3 Richtungen, zusammen '), findsOneWidget);
      expect(
        find.textContaining('MB. Sie werden nacheinander'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Laden'));
      await tester.pumpAndSettle();

      // German first, so German works both ways before the rest arrives.
      expect(store.installs, [enDe, enFr, frEn]);
      expect(find.textContaining('von 3 fertig'), findsNothing);
    });

    testWidgets('with everything here it says so and fetches nothing', (
      tester,
    ) async {
      await pump(tester, installed: [deEn, enDe], offered: [deEn, enDe]);

      final button = find.text('Alle Sprachpakete laden oder aktualisieren');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Alle Sprachpakete sind auf diesem Gerät, jeweils in der neuesten '
          'Fassung.',
        ),
        findsOneWidget,
      );
      expect(store.installs, isEmpty);
    });

    testWidgets('a newer version of a pack here is offered as an update '
        '(#220)', (tester) async {
      await pump(
        tester,
        installed: [deEn, enDe],
        offered: [deEn, enDe],
        versions: {deEn: '1.1'},
      );
      expect(find.textContaining('Fassung 1.0'), findsNWidgets(2));

      final button = find.text('Alle Sprachpakete laden oder aktualisieren');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Sprachpakete aktualisieren?'), findsOneWidget);
      expect(find.textContaining('1 Richtung, zusammen '), findsOneWidget);
      expect(
        find.textContaining('Davon ist 1 die neuere Fassung'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Laden'));
      await tester.pumpAndSettle();

      expect(store.installs, [deEn]);
      expect(find.textContaining('Fassung 1.1'), findsOneWidget);
    });

    testWidgets('what is missing comes before what is merely older', (
      tester,
    ) async {
      await pump(
        tester,
        installed: [deEn],
        offered: [deEn, enDe],
        versions: {deEn: '1.1'},
      );

      final button = find.text('Alle Sprachpakete laden oder aktualisieren');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Alle Sprachpakete laden?'), findsOneWidget);
      expect(find.textContaining('2 Richtungen, zusammen '), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Laden'));
      await tester.pumpAndSettle();

      expect(store.installs, [enDe, deEn]);
    });

    test('only a newer version counts as an update, never an older one', () {
      final catalogue = TranslatorCatalogue({
        deEn: _offered(deEn, version: '1.1'),
        enDe: _offered(enDe, version: '1.1'),
        enFr: _offered(enFr, version: '2.0'),
        frEn: _offered(frEn, version: '1.0'),
      });
      final outdated = outdatedTranslatorPacks(catalogue, [
        _installed(deEn, version: '1.0'),
        // A version Mozilla took back: kept, not swapped for the older one.
        _installed(enDe, version: '2.0'),
        // An early build of the version now released.
        _installed(enFr, version: '2.0a1'),
        _installed(frEn, version: '1.0'),
      ]);
      expect(outdated.map((pack) => pack.direction), [deEn, enFr]);
    });

    testWidgets('closing the question fetches nothing', (tester) async {
      await pump(tester, offered: [deEn, enDe]);

      final button = find.text('Alle Sprachpakete laden oder aktualisieren');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(store.installs, isEmpty);
    });
  });

  test('stopping finishes the pack on its way and starts no other', () async {
    final gate = Completer<void>();
    final slow = _SlowStore(gate.future);
    final container = ProviderContainer(
      overrides: [translatorStoreProvider.overrideWithValue(slow)],
    );
    addTearDown(container.dispose);
    final controller = container.read(translatorInstallProvider.notifier);

    final run = controller.installAll([
      _offered(const TranslatorDirection(_de, _en)),
      _offered(const TranslatorDirection(_en, _de)),
      _offered(const TranslatorDirection(_en, _fr)),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(translatorInstallProvider).batch?.total, 3);

    controller.stopAll();
    expect(container.read(translatorInstallProvider).batch?.stopping, isTrue);
    gate.complete();
    await run;

    expect(slow.installs.map((d) => d.code), ['deen']);
    expect(container.read(translatorInstallProvider).batch, isNull);
  });
}

/// Holds the first install until [gate] opens.
class _SlowStore extends TranslatorStore {
  _SlowStore(this.gate);

  final Future<void> gate;
  final installs = <TranslatorDirection>[];

  @override
  Future<List<InstalledTranslatorPack>> installed() async => const [];

  @override
  Stream<TranslatorInstallProgress> install(TranslatorPack pack) async* {
    installs.add(pack.direction);
    await gate;
    yield TranslatorInstallProgress(received: pack.size, total: pack.size);
  }
}
