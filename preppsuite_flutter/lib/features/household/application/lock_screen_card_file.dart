import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The folder the lock-screen card is written to for the share sheet.
///
/// A folder of its own, so whatever is in it can go in one step: the card
/// names a blood group, allergies and medication, and it is written
/// without the encryption the rest of the household's files get.
Future<Directory> _folder() async => Directory(
  p.join((await getTemporaryDirectory()).path, 'lock-screen-card'),
);

/// Where the card named [baseName] is written before it is shared.
Future<File> lockScreenCardFile(String baseName) async {
  final folder = await _folder();
  await folder.create(recursive: true);
  return File(p.join(folder.path, '$baseName.png'));
}

/// Removes every copy of the card from the temporary folder (#293).
///
/// The comment that came with it said the copy lived for the seconds the
/// share sheet takes. Nothing deleted it: it stayed, unencrypted, until
/// the system happened to clear the folder, and outlived "delete the
/// household and local data". Called once the share sheet is done and by
/// that reset. Also takes the file earlier versions left loose in the
/// folder itself.
Future<void> deleteLockScreenCardFiles() async {
  try {
    final folder = await _folder();
    if (await folder.exists()) await folder.delete(recursive: true);
    final legacy = File(
      p.join(folder.parent.path, 'notfallkarte-sperrbildschirm.png'),
    );
    if (await legacy.exists()) await legacy.delete();
  } on Object {
    // No temporary folder, as in a test; or one already gone.
  }
}
