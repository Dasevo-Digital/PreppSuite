import 'dart:async' show unawaited;

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
