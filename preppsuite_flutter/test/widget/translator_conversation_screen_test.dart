import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/phrasebook/application/phrasebook.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_catalogue.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_providers.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_store.dart';
import 'package:preppsuite_flutter/features/translator/presentation/translator_conversation_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

const _de = PhraseLanguage.de;
const _en = PhraseLanguage.en;

InstalledTranslatorPack _installed(TranslatorDirection direction) =>
    InstalledTranslatorPack(
      direction: direction,
      version: '1.0',
      size: 1,
      modelPath: '/models/${direction.code}/model.bin',
      lexPath: '/models/${direction.code}/lex.bin',
      vocabPath: '/models/${direction.code}/vocab.spm',
    );

class _FakeStore extends TranslatorStore {
  _FakeStore(this.directions);

  final List<TranslatorDirection> directions;

  @override
  Future<List<InstalledTranslatorPack>> installed() async => [
    for (final d in directions) _installed(d),
  ];
}

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<TranslatorDirection> installed,
    ConversationTurn? opening,
    Size size = const Size(420, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          translatorStoreProvider.overrideWithValue(_FakeStore(installed)),
          translatorCatalogueProvider.overrideWith(
            (ref) async => TranslatorCatalogue({}),
          ),
          translateTextProvider.overrideWithValue(
            (text, packs) async =>
                packs.single.direction.from == _de ? 'EN: $text' : 'DE: $text',
          ),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TranslatorConversationScreen(
            mine: _de,
            theirs: _en,
            opening: opening,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder fieldWithHint(String hint) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == hint,
  );

  Finder sendNextTo(Finder field) => find.descendant(
    of: find.ancestor(of: field, matching: find.byType(Row)).first,
    matching: find.byIcon(Icons.send),
  );

  testWidgets('each side writes in its own language and reads the other '
      'translated', (tester) async {
    await pump(
      tester,
      installed: const [
        TranslatorDirection(_de, _en),
        TranslatorDirection(_en, _de),
      ],
    );

    final mine = fieldWithHint('Bitte schreiben Sie Ihre Antwort hier.');
    final theirs = fieldWithHint('Please write your answer here.');
    expect(mine, findsOneWidget);
    expect(theirs, findsOneWidget);

    await tester.enterText(mine, 'Wo tut es weh?');
    await tester.tap(sendNextTo(mine));
    await tester.pumpAndSettle();
    expect(find.text('Wo tut es weh?'), findsOneWidget);
    expect(find.text('EN: Wo tut es weh?'), findsOneWidget);

    await tester.enterText(theirs, 'My arm.');
    await tester.tap(sendNextTo(theirs));
    await tester.pumpAndSettle();
    expect(find.text('My arm.'), findsOneWidget);
    expect(find.text('DE: My arm.'), findsOneWidget);
  });

  testWidgets('a translation from the translator is the first turn', (
    tester,
  ) async {
    await pump(
      tester,
      installed: const [
        TranslatorDirection(_de, _en),
        TranslatorDirection(_en, _de),
      ],
      opening: const ConversationTurn(
        from: _de,
        text: 'Sind Sie verletzt?',
        translation: 'Are you injured?',
      ),
    );

    expect(find.text('Sind Sie verletzt?'), findsOneWidget);
    expect(find.text('Are you injured?'), findsOneWidget);
  });

  testWidgets('without the way back it asks for the missing pack', (
    tester,
  ) async {
    await pump(tester, installed: const [TranslatorDirection(_de, _en)]);

    expect(find.textContaining('beide Richtungen'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('the upper half is turned round on a phone, and can be '
      'turned back', (tester) async {
    await pump(
      tester,
      installed: const [
        TranslatorDirection(_de, _en),
        TranslatorDirection(_en, _de),
      ],
    );

    int turns() =>
        tester.widget<RotatedBox>(find.byType(RotatedBox).first).quarterTurns;
    expect(turns(), 2);

    await tester.tap(find.byIcon(Icons.screen_rotation_alt_outlined));
    await tester.pump();
    expect(turns(), 0);
  });

  testWidgets('on a computer screen it starts unturned', (tester) async {
    await pump(
      tester,
      installed: const [
        TranslatorDirection(_de, _en),
        TranslatorDirection(_en, _de),
      ],
      size: const Size(1200, 900),
    );

    expect(
      tester.widget<RotatedBox>(find.byType(RotatedBox).first).quarterTurns,
      0,
    );
  });
}
