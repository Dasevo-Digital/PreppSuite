import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_storage.dart';

/// How a start of the app found the keychain (#388).
enum KeychainMoveOutcome {
  /// Not iOS: there is nothing to move.
  notNeeded,

  /// Moved at an earlier start.
  alreadyDone,

  /// Every entry is readable after the first unlock now.
  moved,

  /// The device is locked, and the old entries cannot be read. The next
  /// start tries again.
  deviceLocked,

  /// A step failed. Whatever had not moved is where it was, a copy covers
  /// the entry that was being moved, and the next start goes on from
  /// there.
  failed,
}

/// Written once nothing is left to move.
const keychainMoveDoneKey = 'preppsuite.keychainMove.done.v1';

/// Moves this app's keychain entries on iOS to "after first unlock" (#388).
///
/// Up to #388 every entry carried the plugin's default, readable only
/// while the device is unlocked, and the plugin never changes that by
/// itself: a write with other options neither finds the old entry (the
/// accessibility is part of its query) nor may add a second one (the
/// keychain refuses a duplicate of account and service). So each entry is
/// removed and written anew. Among them is the key to the household's
/// database, and the app may be stopped at any moment of this, so the
/// order is:
///
/// 1. write a copy under [keychainMoveCopyPrefix] with the new
///    accessibility, and read it back;
/// 2. remove the entry and write it with the new accessibility, and read
///    it back;
/// 3. remove the copy.
///
/// The entry exists under the old accessibility until 2, the copy from 1
/// to 3 and the entry again from 2 on, so at every moment one of them
/// holds the value, and [AppSecureStorage.read] finds whichever it is.
/// A start after an interruption looks at the copies first: one whose entry
/// still has the old accessibility is written again by the ordinary
/// move; one whose entry is missing writes it back; one whose entry has
/// the new accessibility is surplus, because the entry was written by the
/// move or, later, by the app itself.
///
/// Runs once per start of the app until it is done, before anything else
/// reads the key store and never from the background isolate: there the
/// device is usually locked, and the app's own code must not run between
/// the steps. Never throws.
Future<KeychainMoveOutcome> moveKeychainToFirstUnlock({
  FlutterSecureStorage storage = appSecureStorage,
  void Function(Object error, StackTrace stack)? onError,
}) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
    return KeychainMoveOutcome.notNeeded;
  }
  try {
    final done = await storage.read(
      key: keychainMoveDoneKey,
      iOptions: appleFirstUnlock,
    );
    if (done != null) return KeychainMoveOutcome.alreadyDone;
    if (await storage.isCupertinoProtectedDataAvailable() == false) {
      return KeychainMoveOutcome.deviceLocked;
    }

    final waiting = await storage.readAll(iOptions: appleWhenUnlocked);
    final moved = await storage.readAll(iOptions: appleFirstUnlock);

    for (final MapEntry(key: copyKey, :value) in moved.entries) {
      if (!copyKey.startsWith(keychainMoveCopyPrefix)) continue;
      final key = copyKey.substring(keychainMoveCopyPrefix.length);
      if (waiting.containsKey(key)) continue;
      if (!moved.containsKey(key)) {
        await _writeAndReadBack(storage, key, value);
      }
      await storage.delete(key: copyKey, iOptions: appleFirstUnlock);
    }

    for (final MapEntry(:key, :value) in waiting.entries) {
      final copyKey = '$keychainMoveCopyPrefix$key';
      await _writeAndReadBack(storage, copyKey, value);
      await storage.delete(key: key, iOptions: appleWhenUnlocked);
      await _writeAndReadBack(storage, key, value);
      await storage.delete(key: copyKey, iOptions: appleFirstUnlock);
    }

    await storage.write(
      key: keychainMoveDoneKey,
      value: 'first_unlock',
      iOptions: appleFirstUnlock,
    );
    return KeychainMoveOutcome.moved;
  } on Object catch (error, stack) {
    onError?.call(error, stack);
    return KeychainMoveOutcome.failed;
  }
}

/// Writes [key] with the new accessibility and checks that it reads back.
///
/// A value that does not is removed again rather than left in place: for
/// the copy the entry is still untouched, and for the entry the copy is
/// still there, so either way the value stays readable.
Future<void> _writeAndReadBack(
  FlutterSecureStorage storage,
  String key,
  String value,
) async {
  await storage.write(key: key, value: value, iOptions: appleFirstUnlock);
  if (await storage.read(key: key, iOptions: appleFirstUnlock) != value) {
    await storage.delete(key: key, iOptions: appleFirstUnlock);
    throw StateError('A keychain entry did not read back after the move.');
  }
}
