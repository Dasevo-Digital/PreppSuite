import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../features/sharing/application/folder_crypto.dart' show readEnvelope;
import 'local_database_encryption.dart';
import 'photo_vault.dart';
import 'portable_preferences.dart';
import 'private_preferences.dart';

/// How a carried folder's first start beside an installation went (#392).
enum PortableTakeover {
  /// Nothing to take: the folder holds a household already, or there is
  /// none on this computer.
  none,

  /// The installation's household was copied into the folder, plain.
  taken,

  /// The installation's household is encrypted, and its key could not be
  /// read here. Nothing was copied.
  locked,

  /// The copy did not succeed, or the installation was in the middle of
  /// its upgrade. Nothing was copied.
  failed;

  /// Where a refusal is kept in the folder's settings, so that the
  /// settings card can still say it after the first start.
  static const preferenceKey = 'portableTakeover.v1';

  static PortableTakeover? fromName(Object? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

/// The folder a takeover is put together in, inside the carried folder.
const portableTakeoverStaging = '.preppsuite-uebernahme';
const _complete = 'vollstaendig';
const _settings = 'einstellungen.json';
const _photos = 'inventory_photos';
const _householdDatabase = '$localDatabaseFilePrefix.sqlite';

/// Takes the household of the installation on this computer into the
/// carried [folder], once (#392).
///
/// Until 3.0.3 every start copied whatever databases and pictures the
/// installation had and the folder did not: a disk with a household of its
/// own collected another household's pictures and full-text indexes on
/// every start, a journal the installation had open was put beside the
/// disk's database and rolled back into it, and an encrypted installation
/// arrived as files no other computer opens, with settings and pictures
/// the carried copy itself could not read.
///
/// Now:
///
/// * **Only into a folder without a household.** One that holds a
///   database or any setting has been used, and is never added to.
/// * **All or nothing.** Everything is put together first in
///   [portableTakeoverStaging] inside the folder, and moved into place
///   only when all of it is there. A start cut off while it is moved
///   finishes the move before anything opens the folder.
/// * **Plain.** Databases are copied through SQLite and decrypted on the
///   way (`copyDatabaseAsPlaintext`), sealed settings and pictures are
///   opened with the installation's key. What that key does not open is
///   unreadable in the installation as well and stays behind. Without the
///   key, nothing is copied ([PortableTakeover.locked]).
/// * **No journal without its database**: SQLite's own copy is one
///   consistent file.
///
/// The installation is only read. A refusal is noted in the folder's
/// settings; the way to take such a household along is a backup.
///
/// Throws only when a takeover that was complete could not be moved into
/// place. The folder must then not be used in this run: the next start
/// finishes the move.
Future<PortableTakeover> takeOverInstallation({
  required Directory folder,
  required Directory? installation,
  required PortablePreferencesStore preferences,
  required SharedPreferencesStorePlatform? installedPreferences,
  required Future<InstallationKey> Function() installationKey,
}) async {
  final staging = Directory(p.join(folder.path, portableTakeoverStaging));
  if (await File(p.join(staging.path, _complete)).exists()) {
    await _moveIntoPlace(staging, folder, preferences);
    return PortableTakeover.taken;
  }
  await _discard(staging);
  // Left over and not to be removed: never mixed with a new one.
  if (await staging.exists()) return PortableTakeover.failed;

  if (await _holdsHousehold(folder, preferences)) return PortableTakeover.none;
  final source =
      installation == null || p.equals(installation.path, folder.path)
      ? null
      : installation;

  PortableTakeover outcome;
  try {
    outcome = await _putTogether(
      staging: staging,
      installation: source,
      installedPreferences: installedPreferences,
      installationKey: installationKey,
    );
  } on Object {
    outcome = PortableTakeover.failed;
  }
  if (outcome == PortableTakeover.taken) {
    await _moveIntoPlace(staging, folder, preferences);
    return outcome;
  }
  await _discard(staging);
  if (outcome != PortableTakeover.none) {
    try {
      await preferences.setValue(
        'String',
        'flutter.${PortableTakeover.preferenceKey}',
        outcome.name,
      );
    } on Object {
      // The card cannot say it then. Nothing else depends on it.
    }
  }
  return outcome;
}

/// Whether [folder] has been used: a database, or a single setting.
Future<bool> _holdsHousehold(
  Directory folder,
  PortablePreferencesStore preferences,
) async {
  if ((await LocalDatabaseEncryption.databaseFilesIn(folder)).isNotEmpty) {
    return true;
  }
  return (await preferences.getAll()).isNotEmpty;
}

Future<PortableTakeover> _putTogether({
  required Directory staging,
  required Directory? installation,
  required SharedPreferencesStorePlatform? installedPreferences,
  required Future<InstallationKey> Function() installationKey,
}) async {
  final databases = <File>[];
  final photos = <File>[];
  if (installation != null && await installation.exists()) {
    await for (final entity in installation.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (!name.startsWith(localDatabaseFilePrefix)) continue;
      // An upgrade that stopped half way: the household may be under
      // either name, and copying one of them could be copying the wrong
      // one. The installation repairs it at its next start. The same for
      // the move to chacha20 (#419).
      if (LocalDatabaseEncryption.isMigrationCopy(name)) {
        return PortableTakeover.failed;
      }
      if (name.endsWith('.sqlite')) databases.add(entity);
    }
    final pictures = Directory(p.join(installation.path, _photos));
    if (await pictures.exists()) {
      await for (final entity in pictures.list(followLinks: false)) {
        if (entity is File && !entity.path.endsWith('.tmp')) {
          photos.add(entity);
        }
      }
    }
  }

  Map<String, Object> settings;
  try {
    settings = installedPreferences == null
        ? const {}
        : await installedPreferences.getAll();
  } on Object {
    // A household without its settings is a household without its
    // profile: it would arrive looking empty.
    if (databases.isNotEmpty) return PortableTakeover.failed;
    settings = const {};
  }

  if (databases.isEmpty && photos.isEmpty && settings.isEmpty) {
    return PortableTakeover.none;
  }

  final state = await installationKey();
  if (state.upgrading) return PortableTakeover.failed;
  final key = state.key;
  final dataKey = key == null
      ? null
      : Uint8List.fromList(base64Url.decode(key));

  await staging.create(recursive: true);

  for (final database in databases) {
    if (await LocalDatabaseEncryption.isEncryptedDatabase(database)) {
      if (key == null || !LocalDatabaseEncryption.cipherAvailable) {
        return PortableTakeover.locked;
      }
      await copyDatabaseAsPlaintext(
        database.path,
        p.join(staging.path, p.basename(database.path)),
        key: key,
      );
    } else {
      await copyDatabaseAsPlaintext(
        database.path,
        p.join(staging.path, p.basename(database.path)),
      );
    }
  }

  if (photos.isNotEmpty) {
    final into = Directory(p.join(staging.path, _photos));
    await into.create();
    for (final photo in photos) {
      final stored = await photo.readAsBytes();
      Uint8List? clear = stored;
      if (PhotoVault.isSealed(stored)) {
        if (dataKey == null) return PortableTakeover.locked;
        clear = await PhotoVault.openWith(stored, dataKey);
      }
      // Sealed under a key that does not open it: unreadable in the
      // installation just the same.
      if (clear == null) continue;
      await File(
        p.join(into.path, p.basename(photo.path)),
      ).writeAsBytes(clear, flush: true);
    }
  }

  final plain = <String, Object>{};
  for (final MapEntry(:key, :value) in settings.entries) {
    if (value is String && readEnvelope(value) != null) {
      if (dataKey == null) return PortableTakeover.locked;
      final clear = await PrivatePreferences.openWith(value, dataKey);
      if (clear != null) plain[key] = clear;
      continue;
    }
    plain[key] = value;
  }
  await File(
    p.join(staging.path, _settings),
  ).writeAsString(jsonEncode(plain), flush: true);

  // Last: from here on the takeover is finished by whichever start comes
  // next, rather than begun again.
  await File(p.join(staging.path, _complete)).writeAsString('', flush: true);
  return PortableTakeover.taken;
}

/// Moves what [_putTogether] gathered into [folder]. Can be repeated: what
/// is in place already stays as it is.
Future<void> _moveIntoPlace(
  Directory staging,
  Directory folder,
  PortablePreferencesStore preferences,
) async {
  final pictures = Directory(p.join(staging.path, _photos));
  if (await pictures.exists()) {
    final into = Directory(p.join(folder.path, _photos));
    await into.create(recursive: true);
    await for (final entity in pictures.list(followLinks: false)) {
      if (entity is! File) continue;
      final target = File(p.join(into.path, p.basename(entity.path)));
      if (!await target.exists()) await entity.rename(target.path);
    }
  }

  // The household's own database last of the databases.
  final databases = [
    await for (final entity in staging.list(followLinks: false))
      if (entity is File && entity.path.endsWith('.sqlite')) entity,
  ]..sort((a, b) => _householdLast(a).compareTo(_householdLast(b)));
  for (final database in databases) {
    final target = File(p.join(folder.path, p.basename(database.path)));
    if (!await target.exists()) await database.rename(target.path);
  }

  final staged = File(p.join(staging.path, _settings));
  if (await staged.exists()) {
    final decoded = jsonDecode(await staged.readAsString());
    if (decoded is Map) {
      await preferences.putAllAbsent({
        for (final MapEntry(:key, :value) in decoded.entries)
          if (key is String && value != null) key: value as Object,
      });
    }
  }

  await staging.delete(recursive: true);
}

int _householdLast(File file) =>
    p.basename(file.path) == _householdDatabase ? 1 : 0;

/// Removes a takeover that was never finished. Only ever its own folder,
/// which holds copies: the installation keeps its originals.
Future<void> _discard(Directory staging) async {
  try {
    if (await staging.exists()) await staging.delete(recursive: true);
  } on Object {
    // Tried again by the next start.
  }
}
