import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _crisisModeKey = 'crisisModeGlobal';

/// Device-wide crisis presentation: larger controls and no app animations.
class CrisisModeController extends Notifier<bool> {
  @override
  bool build() {
    unawaited(_load());
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (ref.mounted) state = prefs.getBool(_crisisModeKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_crisisModeKey, value);
  }
}

final crisisModeProvider = NotifierProvider<CrisisModeController, bool>(
  CrisisModeController.new,
);

/// The text size in crisis mode: at least a quarter larger than the
/// default, and never smaller than what the person already chose.
///
/// One place for it, because there are two switches that use it — this
/// device-wide one and the crisis hub's own — and the hub's used to set a
/// fixed 1.25, or 1.0 when off, over whatever the system said. Somebody
/// who reads at 1.5 got smaller text from asking for larger.
TextScaler crisisTextScaler(TextScaler inherited) => TextScaler.linear(
  inherited.scale(16).clamp(20.0, double.infinity) / 16,
);
