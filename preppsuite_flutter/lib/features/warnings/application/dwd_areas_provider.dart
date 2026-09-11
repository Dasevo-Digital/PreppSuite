import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../household/application/german_states.dart';
import 'dwd_areas.dart';

/// The DWD's warncell table, for the screens that want to name a region
/// rather than print its number.
///
/// The table itself is loaded once and cached by [DwdAreas.load]; this is
/// only the way a widget gets at it. Null on failure rather than an error
/// state: every reader here is showing a label, and a settings screen
/// that will not open because a lookup table is missing would be a far
/// worse failure than a key shown as a key.
final dwdAreasProvider = FutureProvider<DwdAreas?>((ref) async {
  try {
    return await DwdAreas.load();
  } on Object {
    return null;
  }
});

/// A five- or twelve-digit Kreisschluessel written out, or null when it
/// cannot be placed.
///
/// What this is for: `031010000000` is unverifiable — it is exactly as
/// plausible as the key for somewhere else entirely, and somebody
/// checking whether their region is right has nothing to check against.
String? describeRegionKey(DwdAreas? areas, String? regionKey) {
  if (areas == null || regionKey == null) return null;

  final district = areas.describeDistrict(regionKey);
  if (district == null) return null;

  final code = district.state;
  final state = code == null ? null : germanStateByBbkCode(code)?.nameDe;
  return state == null ? district.name : '${district.name} · $state';
}
