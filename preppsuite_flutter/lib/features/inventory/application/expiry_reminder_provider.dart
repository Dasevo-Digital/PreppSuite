import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'expiry_reminder_planner.dart';

const _expiryLeadDaysPrefsKey = 'expiryLeadDays';

/// Lead times the user can pick from, in days. Kept to a short list of
/// round numbers rather than a free-form field: the exact number matters
/// far less than having one far-off and one last-chance reminder, and a
/// picker cannot produce a nonsensical value.
const selectableExpiryLeadDays = [90, 60, 30, 14, 7, 3, 1];

/// How many days before expiry the user wants to be reminded. Empty means
/// no expiry reminders at all, which is a valid choice and distinct from
/// having notifications switched off entirely — see
/// `notificationsEnabledProvider`, which gates these as well.
///
/// Persisted as a comma-separated string because `SharedPreferences` has
/// no int-list type; `setStringList` would work but round-trips through
/// string parsing anyway.
class ExpiryLeadDaysController extends Notifier<List<int>> {
  @override
  List<int> build() {
    unawaited(_loadInitial());
    return defaultExpiryLeadDays;
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    // See LocaleOverrideController for why this guard is needed after an
    // async gap.
    if (!ref.mounted) return;

    final stored = prefs.getString(_expiryLeadDaysPrefsKey);
    if (stored == null) return;
    state = _decode(stored);
  }

  Future<void> setLeadDays(List<int> leadDays) async {
    final normalized = _normalize(leadDays);
    state = normalized;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_expiryLeadDaysPrefsKey, normalized.join(','));
  }

  Future<void> toggle(int leadDay) {
    final next = state.contains(leadDay)
        ? (state.toList()..remove(leadDay))
        : (state.toList()..add(leadDay));
    return setLeadDays(next);
  }

  /// An empty stored value is a deliberate "no reminders", so it must not
  /// fall back to the defaults the way a missing key does.
  static List<int> _decode(String stored) {
    if (stored.isEmpty) return const [];
    return _normalize(
      stored
          .split(',')
          .map((part) => int.tryParse(part.trim()))
          .whereType<int>()
          .toList(),
    );
  }

  static List<int> _normalize(List<int> leadDays) {
    final valid =
        leadDays.where(selectableExpiryLeadDays.contains).toSet().toList()
          ..sort((a, b) => b.compareTo(a));
    return valid;
  }
}

final expiryLeadDaysProvider =
    NotifierProvider<ExpiryLeadDaysController, List<int>>(
      ExpiryLeadDaysController.new,
    );
