import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// The channel the native side answers on — `MainActivity.kt` on Android,
/// `StorageBridge.swift` on iOS and on macOS.
///
/// One channel for two features — the shared folder and the offline
/// archives — because they need the same thing: a folder or a file the
/// user picked, reachable after a restart. One channel for three
/// platforms for the same reason: what they hand back differs, but what
/// has to be done with it does not.
const nativeStorageChannel = MethodChannel('preppsuite/storage');

/// Whether picking has to go through the native side rather than
/// `file_picker`.
///
/// On Android scoped storage means `dart:io` can open neither a picked
/// folder nor a picked file. On iOS and macOS a picked URL works only
/// while the process lives, and only inside a security scope. All three
/// therefore hand back a handle instead of a path — and on all three, the
/// point of doing it ourselves is the permission taken afterwards, not the
/// dialog.
///
/// macOS was the exception here for as long as the app turned its sandbox
/// off. It no longer does, which is also what stopped the system asking
/// for folder access again after every update; see
/// `macos/Runner/Release.entitlements`.
bool get usesNativeStoragePicker {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}

/// Something the user picked, in a form that survives a restart.
///
/// [value] is a filesystem path on Linux and Windows. On Android it is a
/// `content://` URI and on iOS and macOS a `bookmark://` handle standing
/// for a stored security-scoped bookmark — hence [label], because neither
/// is something to show anyone.
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

/// Whether a stored handle has to be resolved before ordinary file I/O
/// can touch what it points at.
///
/// Only macOS. Android hands out `content://` URIs that `dart:io` can
/// never open, and iOS keeps its archives inside the app's own storage —
/// on both, everything goes through the channel and there is no path to
/// resolve to. On macOS the sandbox is a gate rather than a wall: once
/// the security scope is held, the path behind it behaves like any other.
bool get usesStorageBookmarks {
  if (kIsWeb) return false;
  return Platform.isMacOS;
}

/// Turns a stored handle back into a path the app may use with `dart:io`,
/// opening the security scope that makes it usable.
///
/// Returns null when the handle no longer resolves — the folder deleted,
/// the volume not mounted — and on the platforms that have no such thing.
/// The scope stays open for the life of the process, which is what makes
/// the returned path keep working after this call.
Future<String?> resolveStoragePath(String handle) async {
  if (!usesStorageBookmarks || !isNativeStorageHandle(handle)) return null;
  try {
    return await nativeStorageChannel.invokeMethod<String>('resolvePath', {
      'uri': handle,
    });
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}

/// Turns a path the app can currently reach into a handle that survives
/// a restart.
///
/// For the files the app writes itself: a download lands in a folder the
/// user picked, and the app can reach it at that moment — but a bare path
/// into that folder is unusable on the next launch, when no security
/// scope is open. Making the bookmark while the door is still open is
/// what turns a finished download into one that is still there tomorrow.
///
/// Returns null where there is nothing to do, which is every platform but
/// macOS, and on failure. Callers fall back to the plain path: it still
/// works for the rest of this run.
Future<PickedStorage?> rememberStoragePath(
  String path, {
  required String label,
}) async {
  if (!usesStorageBookmarks) return null;
  try {
    final result = await nativeStorageChannel.invokeMapMethod<String, String>(
      'remember',
      {'path': path},
    );
    final uri = result?['uri'];
    if (uri == null) return null;
    return PickedStorage(value: uri, label: label);
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}
