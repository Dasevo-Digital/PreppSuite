import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// The channel `MainActivity` answers on. Android only.
///
/// One channel for two features — the shared folder and the offline map
/// archive — because they need the same thing: a folder or a file the user
/// picked, reachable after a restart.
const nativeStorageChannel = MethodChannel('preppsuite/storage');

/// Whether picked storage arrives as a `content://` URI rather than a path.
///
/// True only on Android, where scoped storage means `dart:io` can open
/// neither a picked folder nor a picked file.
bool get usesStorageAccessFramework {
  if (kIsWeb) return false;
  return Platform.isAndroid;
}

/// Something the user picked, in a form that survives a restart.
///
/// [value] is a filesystem path everywhere but Android, where it is a
/// `content://` URI — hence [label], because a content URI is not
/// something to show anyone.
class PickedStorage {
  const PickedStorage({required this.value, required this.label});

  final String value;
  final String label;

  /// Whether this needs the Storage Access Framework rather than
  /// `dart:io`. Read from the value itself, so a device that switched
  /// platforms — a restored backup, a synced preference — cannot be
  /// handed the wrong reader.
  bool get isContentUri => value.startsWith('content://');
}
