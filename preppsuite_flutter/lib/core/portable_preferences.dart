import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

/// Keeps the settings in a file inside the portable folder.
///
/// Registered in place of the platform's own store, which is why the
/// twenty-six places that read a setting need to know nothing about any
/// of this.
///
/// A store of our own rather than pointing the platform's at another
/// directory, for one decisive reason: on macOS the platform store is
/// `NSUserDefaults`, which is not a file in a directory at all and cannot
/// be pointed anywhere. One implementation that behaves the same on all
/// three desktops is worth more than three that nearly do.
///
/// The file is JSON and deliberately readable. Somebody carrying this on
/// a stick can look at what is in it, and — since the app is to be given
/// away with its source — can see that there is nothing in it they were
/// not told about.
class PortablePreferencesStore extends SharedPreferencesStorePlatform {
  PortablePreferencesStore(this.file);

  /// Opens the store in [directory], reading what is already there.
  static Future<PortablePreferencesStore> open(Directory directory) async {
    await directory.create(recursive: true);
    final store = PortablePreferencesStore(
      File('${directory.path}${Platform.pathSeparator}$fileName'),
    );
    await store._read();
    return store;
  }

  static const fileName = 'einstellungen.json';

  /// The prefix `shared_preferences` puts on every key it owns.
  static const _prefix = 'flutter.';

  final File file;

  final _values = <String, Object>{};
  var _loaded = false;

  /// The write in flight, so two settings saved at once do not race for
  /// the file. Settings are saved on almost every screen here, and two
  /// of them landing together is ordinary rather than rare.
  Future<void> _writing = Future.value();

  @override
  bool get isMock => false;

  Future<void> _read() async {
    if (_loaded) return;
    _loaded = true;
    try {
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return;
      for (final entry in decoded.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String) continue;
        // A list comes back from JSON as `List<dynamic>`, and
        // `shared_preferences` hands out `List<String>`. Anything else
        // stored as a list was not written by this app.
        if (value is List) {
          _values[key] = [for (final item in value) '$item'];
        } else if (value is bool || value is num || value is String) {
          _values[key] = value as Object;
        }
      }
    } on Object {
      // A truncated or hand-edited file loses the settings, not the app.
      // Every one of them is a preference that can be set again; refusing
      // to start over a stray character would be the worse trade.
      _values.clear();
    }
  }

  Future<void> _write() {
    final snapshot = Map<String, Object>.from(_values);
    return _writing = _writing.then((_) async {
      try {
        // Written beside and renamed over, so a pull of the stick
        // half-way through leaves the previous settings rather than half
        // of the new ones. On a carried disk that is not a theoretical
        // failure — it is how the disk usually goes away.
        final temporary = File('${file.path}.neu');
        await temporary.writeAsString(jsonEncode(snapshot), flush: true);
        await temporary.rename(file.path);
      } on Object {
        // The disk is gone or full. The value is still in memory, so the
        // session behaves; there is nowhere to report this from, and
        // taking down the app over a saved filter would be absurd.
        return;
      }
    });
  }

  @override
  Future<bool> clear() => clearWithParameters(
    ClearParameters(filter: PreferencesFilter(prefix: _prefix)),
  );

  @override
  Future<bool> clearWithParameters(ClearParameters parameters) async {
    await _read();
    final filter = parameters.filter;
    _values.removeWhere(
      (key, _) =>
          key.startsWith(filter.prefix) &&
          (filter.allowList == null || filter.allowList!.contains(key)),
    );
    await _write();
    return true;
  }

  @override
  Future<Map<String, Object>> getAll() => getAllWithParameters(
    GetAllParameters(filter: PreferencesFilter(prefix: _prefix)),
  );

  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) async {
    await _read();
    final filter = parameters.filter;
    return {
      for (final entry in _values.entries)
        if (entry.key.startsWith(filter.prefix) &&
            (filter.allowList == null || filter.allowList!.contains(entry.key)))
          entry.key: entry.value,
    };
  }

  @override
  Future<bool> remove(String key) async {
    await _read();
    _values.remove(key);
    await _write();
    return true;
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    await _read();
    _values[key] = value;
    await _write();
    return true;
  }
}

/// Copies the settings an installed copy left behind into [store], once.
///
/// Without this, putting the folder beside the program turns a working
/// installation into an empty one: the household is still in the
/// database, but which map archive is in use, which warning regions are
/// watched and where downloads go are all preferences, and they would be
/// gone. Copied rather than moved, because the installed copy may still
/// be used on this machine — the stick is a second way in, not a
/// replacement.
///
/// Runs only when the portable file has nothing in it at all. A folder
/// that has been used once is never written over.
/// [installed] is the platform's own store, which has to be taken hold of
/// **before** this one is registered in its place — on Linux and Windows
/// it is an ordinary Dart object, not a channel, so there is no getting
/// it back afterwards.
Future<void> adoptInstalledPreferences(
  PortablePreferencesStore store,
  SharedPreferencesStorePlatform installed,
) async {
  if ((await store.getAll()).isNotEmpty) return;

  final Map<String, Object> existing;
  try {
    existing = await installed.getAll();
  } on Object {
    return;
  }

  for (final entry in existing.entries) {
    await store.setValue(_typeName(entry.value), entry.key, entry.value);
  }
}

String _typeName(Object value) => switch (value) {
  bool() => 'Bool',
  int() => 'Int',
  double() => 'Double',
  String() => 'String',
  _ => 'StringList',
};
