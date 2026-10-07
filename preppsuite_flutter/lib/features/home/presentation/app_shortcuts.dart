import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../first_aid/presentation/first_aid_screen.dart';
import '../../household/presentation/emergency_cards_screen.dart';
import 'check_in_screen.dart';

/// The actions a long press on the app icon offers (#123). Draws nothing.
///
/// In an emergency the seconds between unlocking a phone and reaching the
/// right screen are the ones this saves: 112, a sign of life, first aid
/// and the emergency cards straight from the home screen. iOS and Android
/// only -- the desktops have no such menu.
class AppShortcuts extends StatefulWidget {
  const AppShortcuts({
    super.key,
    required this.householdId,
    this.quickActions = const QuickActions(),
    this.launch,
    @visibleForTesting this.enabled,
  });

  final String householdId;

  /// Injectable for tests.
  final QuickActions quickActions;
  final Future<bool> Function(Uri uri)? launch;

  /// Overrides the platform check, for tests.
  final bool? enabled;

  static const call112 = 'call-112';
  static const checkIn = 'check-in';
  static const firstAid = 'first-aid';
  static const emergencyCards = 'emergency-cards';

  static bool get supported =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  @override
  State<AppShortcuts> createState() => _AppShortcutsState();
}

class _AppShortcutsState extends State<AppShortcuts> {
  String? _localeName;

  @override
  void initState() {
    super.initState();
    if (!(widget.enabled ?? AppShortcuts.supported)) return;
    // A start from a shortcut is delivered here as well, once the handler
    // is in place, which is why it is set before anything else.
    widget.quickActions.initialize(_open);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!(widget.enabled ?? AppShortcuts.supported)) return;
    final l10n = AppLocalizations.of(context)!;
    // Written again when the language changes, and only then.
    if (_localeName == l10n.localeName) return;
    _localeName = l10n.localeName;
    widget.quickActions.setShortcutItems([
      ShortcutItem(
        type: AppShortcuts.call112,
        localizedTitle: l10n.emergencyCall112,
      ),
      ShortcutItem(
        type: AppShortcuts.checkIn,
        localizedTitle: l10n.checkInTitle,
      ),
      ShortcutItem(
        type: AppShortcuts.firstAid,
        localizedTitle: l10n.firstAidTitle,
      ),
      ShortcutItem(
        type: AppShortcuts.emergencyCards,
        localizedTitle: l10n.emergencyCardsTitle,
      ),
    ]);
  }

  void _open(String type) {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    switch (type) {
      case AppShortcuts.call112:
        (widget.launch ?? launchUrl)(Uri(scheme: 'tel', path: '112'));
      case AppShortcuts.checkIn:
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => CheckInScreen(householdId: widget.householdId),
          ),
        );
      case AppShortcuts.firstAid:
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const FirstAidScreen()),
        );
      case AppShortcuts.emergencyCards:
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) =>
                EmergencyCardsScreen(householdId: widget.householdId),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
