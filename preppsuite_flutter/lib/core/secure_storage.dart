import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The device's key store, and the one way this app reaches it.
///
/// `resetOnError` is off, which is why there is one place for this (#335).
/// Left at the plugin's default, any exception while reading from the
/// Android keystore deletes the entry, or everything, and answers as if
/// nothing had been there. For most apps that is a login to repeat. Here
/// the entry is the key to the household's database, and a keystore that
/// fails once would have cost the data for good. With the option off a
/// failed read stays a failed read: the app comes up in recovery and can
/// ask again.
///
/// On iOS an entry is written readable from the first unlock after a
/// restart on (#388), not only while the device is unlocked. The warning
/// poll runs as a background task, and that is a locked phone more often
/// than not: with the plugin's default it got no key, could not open the
/// database and never warned anybody. Not the `_this_device` variant, so
/// an encrypted backup still carries the key to a new phone exactly as it
/// did before. Entries written before that are moved once, at the start
/// of the app (`keychain_accessibility_move.dart`). macOS keeps the
/// plugin's default.
const appSecureStorage = AppSecureStorage._();

/// How the app writes on iOS (#388).
const appleFirstUnlock = IOSOptions(
  accessibility: KeychainAccessibility.first_unlock,
);

/// How every entry was written on iOS before #388: the plugin's default.
const appleWhenUnlocked = IOSOptions(
  accessibility: KeychainAccessibility.unlocked,
);

/// Where the move keeps an entry while it rewrites it (#388).
///
/// The plugin cannot change the accessibility of an entry in place, so the
/// move removes the entry and writes it anew, with this copy beside it for
/// the moment in between. Here because reading and deleting have to know
/// about it too; see [AppSecureStorage].
const keychainMoveCopyPrefix = 'preppsuite.keychainMove.copy.';

/// A lookup that finds an entry whatever its accessibility.
///
/// The plugin (flutter_secure_storage_darwin 0.3) puts the accessibility
/// into every query, and the keychain treats it as a filter. An entry from
/// before #388 is therefore invisible to a lookup with [appleFirstUnlock]
/// and reads as missing: for the database key that is the recovery screen,
/// for the app lock a locked-out app. Until the move has run, and in a
/// background task that starts before it could, lookups leave the
/// attribute out. There is never more than one entry per key to find: the
/// keychain tells entries apart by account and service, not by
/// accessibility.
const _appleAnyAccessibility = IOSOptions(accessibility: null);

bool get _onIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// [FlutterSecureStorage] with the options above.
///
/// A type of its own because on iOS reading and deleting differ from
/// writing. Without options of its own, a read
///
/// - finds an entry whatever its accessibility (see
///   [_appleAnyAccessibility]), and
/// - finds the move's copy where the entry itself is missing. That is the
///   moment between removing an entry and writing it anew, or a start
///   after the app was stopped right there. Read at any moment of the
///   move, the database key is there.
///
/// A delete removes the copy as well, first, so that a removed entry does
/// not come back from it. Calls that name their options, as the move's
/// do, get exactly the plugin's behaviour.
class AppSecureStorage extends FlutterSecureStorage {
  const AppSecureStorage._()
    : super(
        aOptions: const AndroidOptions(resetOnError: false),
        iOptions: appleFirstUnlock,
      );

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    Future<String?> lookUp(String key) => super.read(
      key: key,
      iOptions: iOptions ?? _appleAnyAccessibility,
      aOptions: aOptions,
      lOptions: lOptions,
      webOptions: webOptions,
      mOptions: mOptions,
      wOptions: wOptions,
    );

    final value = await lookUp(key);
    if (value != null || iOptions != null || !_onIOS) return value;
    return lookUp('$keychainMoveCopyPrefix$key');
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    Future<void> remove(String key) => super.delete(
      key: key,
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      webOptions: webOptions,
      mOptions: mOptions,
      wOptions: wOptions,
    );

    if (iOptions == null && _onIOS) {
      await remove('$keychainMoveCopyPrefix$key');
    }
    await remove(key);
  }
}
