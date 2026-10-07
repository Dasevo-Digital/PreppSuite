import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/presentation/app_shortcuts.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:quick_actions/quick_actions.dart';

/// The long-press menu on the app icon (#123).
void main() {
  testWidgets('four actions in the app language, and 112 dials', (
    tester,
  ) async {
    final actions = _FakeQuickActions();
    final launched = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AppShortcuts(
            householdId: 'home',
            quickActions: actions,
            enabled: true,
            launch: (uri) async {
              launched.add(uri);
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(actions.items.map((i) => i.localizedTitle), [
      'Notruf 112',
      'Lebenszeichen senden',
      'Erste Hilfe',
      'Notfallkarten',
    ]);
    actions.handler!(AppShortcuts.call112);
    expect(launched.single.toString(), 'tel:112');
  });

  testWidgets('nothing is registered where the platform has no menu', (
    tester,
  ) async {
    final actions = _FakeQuickActions();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppShortcuts(
          householdId: 'home',
          quickActions: actions,
          enabled: false,
        ),
      ),
    );
    expect(actions.items, isEmpty);
    expect(actions.handler, isNull);
  });
}

class _FakeQuickActions extends QuickActions {
  _FakeQuickActions();

  List<ShortcutItem> items = const [];
  QuickActionHandler? handler;

  @override
  Future<void> initialize(QuickActionHandler handler) async =>
      this.handler = handler;

  @override
  Future<void> setShortcutItems(List<ShortcutItem> items) async =>
      this.items = items;
}
