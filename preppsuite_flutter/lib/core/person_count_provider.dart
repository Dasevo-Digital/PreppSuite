import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _personCountPrefsKey = 'supplyCalculatorPersonCount';

/// How many people the "Vorräte für X Tage" supply calculator
/// (`supply_calculator.dart`) plans for. Deliberately a local, per-device
/// preference rather than a household-shared field for now — mirrors
/// `theme_provider.dart`'s `SharedPreferences` shape exactly. A shared,
/// household-wide person count would be a separate future enhancement.
class PersonCountController extends Notifier<int> {
  @override
  int build() {
    unawaited(_loadInitial());
    return 1;
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    // See LocaleOverrideController for why this guard is needed after an
    // async gap.
    if (!ref.mounted) return;
    final stored = prefs.getInt(_personCountPrefsKey);
    if (stored != null) state = stored;
  }

  Future<void> setPersonCount(int count) async {
    if (count < 1) return;
    state = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_personCountPrefsKey, count);
  }
}

final personCountProvider = NotifierProvider<PersonCountController, int>(
  PersonCountController.new,
);
