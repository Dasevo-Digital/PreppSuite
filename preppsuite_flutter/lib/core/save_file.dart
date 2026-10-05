import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Lets the person choose where a file goes, and puts it there (#110).
///
/// The file picker behaves differently by platform, and getting that
/// wrong cost a household its backup on the iPhone:
///
/// * On iOS and Android the picker writes the bytes itself, into a place
///   the person chose -- iCloud Drive, "On My iPhone", a document provider.
///   That place lies outside the app's sandbox. The path that comes back
///   names it, but the app may not open it, and the old follow-up check
///   (`existsSync`, then writing if empty) threw "the file could not be
///   reached" for a file that had in fact just been saved.
/// * On macOS, Windows and Linux the picker only names a path, and the app
///   writes the file itself.
///
/// Returns whether a file was saved; false when the person cancelled.
/// Errors from writing on the desktop are thrown, so the caller can say
/// what went wrong.
Future<bool> saveFileWithPicker({
  required String dialogTitle,
  required String fileName,
  required String extension,
  required Uint8List bytes,
  @visibleForTesting
  Future<String?> Function({
    required String dialogTitle,
    required String fileName,
    required List<String> allowedExtensions,
    required Uint8List bytes,
  })?
  pick,
  @visibleForTesting bool? pickerWrites,
}) async {
  final path = await (pick ?? _pick)(
    dialogTitle: dialogTitle,
    fileName: fileName,
    allowedExtensions: [extension],
    bytes: bytes,
  );
  if (path == null) return false;

  // The picker has written it. Touching the path now is what failed.
  if (pickerWrites ?? _pickerWrites) return true;

  final file = File(path);
  if (!file.existsSync() || file.lengthSync() == 0) {
    await file.writeAsBytes(bytes, flush: true);
  }
  return true;
}

bool get _pickerWrites => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

Future<String?> _pick({
  required String dialogTitle,
  required String fileName,
  required List<String> allowedExtensions,
  required Uint8List bytes,
}) => FilePicker.platform.saveFile(
  dialogTitle: dialogTitle,
  fileName: fileName,
  type: FileType.custom,
  allowedExtensions: allowedExtensions,
  bytes: bytes,
);
