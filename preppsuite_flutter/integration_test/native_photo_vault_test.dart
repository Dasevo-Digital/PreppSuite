import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:preppsuite_flutter/core/local_database_encryption.dart';
import 'package:preppsuite_flutter/core/photo_vault.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_photo_service.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/stored_photo_image.dart';

/// Photos at rest, on a real device: the platform's own key store, the
/// app's own support folder, and the engine's own image decoder.
///
/// The unit suite proves the format with a key held in memory. What only
/// a device can say is whether this installation gets a key at all — an
/// ad-hoc signed macOS build, a Linux session without libsecret — and
/// whether a picture an older version left in the clear is still shown
/// after the update has sealed it.
///
/// Run under a bundle identifier of its own on macOS. The app's ordinary
/// one would open the real household's container and keychain.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Uint8List jpeg(int shade) => Uint8List.fromList(
    img.encodeJpg(
      img.Image(width: 64, height: 48)
        ..clear(img.ColorRgb8(shade, 120, 200 - shade)),
    ),
  );

  Future<bool> shows(WidgetTester tester, String path) async {
    Object? failure;
    var loaded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Image(
          image: ResizeImage.resizeIfNeeded(96, null, StoredPhotoImage(path)),
          errorBuilder: (_, error, _) {
            failure = error;
            return const Text('missing');
          },
          frameBuilder: (_, child, frame, _) {
            if (frame != null) loaded = true;
            return child;
          },
        ),
      ),
    );
    for (var i = 0; i < 50 && !loaded && failure == null; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    if (failure != null) debugPrint('photo $path failed: $failure');
    return loaded;
  }

  testWidgets('pictures from an older version are sealed and still shown', (
    tester,
  ) async {
    await tester.runAsync(
      LocalDatabaseEncryption.instance.initializeOrMarkUnavailable,
    );
    final encryption = LocalDatabaseEncryption.instance;
    final hasKey = encryption.dataKeyBytes != null;
    debugPrint(
      'data key: ${hasKey ? 'present' : 'absent'}, mode ${encryption.mode}',
    );
    if (!hasKey) {
      // Why, in the platform's own words: on macOS an ad-hoc signed build
      // is refused with -34018, a missing entitlement, the moment it tries
      // to store the key. A key no app uses, written and deleted again.
      // Caught inside: `runAsync` would otherwise swallow it.
      final answer = await tester.runAsync(() async {
        const storage = FlutterSecureStorage();
        try {
          await storage.write(key: 'preppsuite.verifyProbe', value: 'x');
          await storage.delete(key: 'preppsuite.verifyProbe');
          return 'writable';
        } on Object catch (error) {
          return '$error';
        }
      });
      debugPrint('key store probe: $answer');
    }

    final folder = (await tester.runAsync(
      const InventoryPhotoService().photosDirectory,
    ))!;
    debugPrint('photo folder: ${folder.path}');

    // What an older version left behind: plain JPEGs.
    final opened = File('${folder.path}/verify-opened.jpg');
    final untouched = File('${folder.path}/verify-untouched.jpg');
    await tester.runAsync(() async {
      await opened.writeAsBytes(jpeg(40), flush: true);
      await untouched.writeAsBytes(jpeg(160), flush: true);
    });
    addTearDown(() {
      for (final file in [opened, untouched]) {
        if (file.existsSync()) file.deleteSync();
      }
    });

    // Opened on screen first: shown, and sealed by that read.
    expect(await shows(tester, opened.path), isTrue, reason: 'plain, shown');
    expect(PhotoVault.isSealed(opened.readAsBytesSync()), hasKey);

    // The start-up sweep takes the rest.
    final sealed = await tester.runAsync(
      () => const PhotoVault().sealDirectory(folder),
    );
    debugPrint('sealed by the sweep: $sealed');
    expect(PhotoVault.isSealed(untouched.readAsBytesSync()), hasKey);

    // Both still shown once sealed — from a fresh cache, so the decoder
    // really is handed what the vault opened.
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    expect(await shows(tester, opened.path), isTrue, reason: 'sealed, shown');
    expect(await shows(tester, untouched.path), isTrue, reason: 'swept, shown');

    // And a new picture is sealed from the start.
    final taken = await tester.runAsync(
      () => const InventoryPhotoService().saveBytes(jpeg(90)),
    );
    final takenFile = File(InventoryPhotoService.resolvePhotoPath(taken!));
    addTearDown(() {
      if (takenFile.existsSync()) takenFile.deleteSync();
    });
    expect(PhotoVault.isSealed(takenFile.readAsBytesSync()), hasKey);
    expect(await shows(tester, takenFile.path), isTrue, reason: 'new, shown');

    // Last, so that everything above has been checked either way: a
    // device without a key keeps its pictures in the clear, and that is
    // the finding, not a detail.
    expect(hasKey, isTrue, reason: 'without a key photos stay in the clear');
  });
}
