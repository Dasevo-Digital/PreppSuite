import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// The channel the native side answers on — `MainActivity.kt` on Android,
/// `StorageBridge.swift` on iOS.
///
/// One channel for two features — the shared folder and the offline
/// archives — because they need the same thing: a folder or a file the
/// user picked, reachable after a restart. One channel for two platforms
/// for the same reason: what they hand back differs, but what has to be
/// done with it does not.
const nativeStorageChannel = MethodChannel('preppsuite/storage');

/// Whether picking has to go through the native side rather than
/// `file_picker`.
///
/// On Android scoped storage means `dart:io` can open neither a picked
/// folder nor a picked file. On iOS a picked URL works only while the
/// process lives, and only inside a security scope. Both therefore hand
/// back a handle instead of a path — and on both, the point of doing it
/// ourselves is the permission taken afterwards, not the dialog.
///
/// macOS is the exception among Apple's platforms because this app turns
/// its sandbox off; see `macos/Runner/Release.entitlements`.
bool get usesNativeStoragePicker {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

/// Something the user picked, in a form that survives a restart.
///
/// [value] is a filesystem path on the desktops. On Android it is a
/// `content://` URI and on iOS a `bookmark://` handle standing for a
/// stored security-scoped bookmark — hence [label], because neither is
/// something to show anyone.
bool isNativeStorageHandle(String value) =>
    value.startsWith('content://') || value.startsWith('bookmark://');

class PickedStorage {
  const PickedStorage({required this.value, required this.label});

  final String value;
  final String label;

  /// Whether this has to be read through the native side rather than
  /// `dart:io`. Read from the value itself, so a device that switched
  /// platforms — a restored backup, a synced preference — cannot be
  /// handed the wrong reader.
  bool get isNativeHandle => isNativeStorageHandle(value);
}
