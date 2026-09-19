import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:preppsuite_flutter/features/possessions/application/possession_controller.dart';
import 'package:preppsuite_flutter/features/possessions/presentation/possessions_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Photos are stored at up to 2000 pixels wide (`InventoryPhotoService`),
/// and this list draws them at 48 by 48. What decides the memory cost is
/// not the size on screen but the size Flutter decodes to, and every tile
/// is built at once here — so a household that documented forty rooms for
/// its insurer pays for forty full-size bitmaps.
void main() {
  late Directory photos;

  setUp(() async {
    photos = await Directory.systemTemp.createTemp('preppsuite-photos');
    // One file per item: the image cache is keyed by path, so eight
    // tiles sharing one picture would measure a single decode and hide
    // exactly what this is about.
    for (var i = 0; i < 8; i++) {
      final picture = img.Image(width: 2000, height: 1500);
      img.fill(picture, color: img.ColorRgb8(90, 140 + i, 90));
      File('${photos.path}/photo-$i.jpg')
        ..createSync()
        ..writeAsBytesSync(img.encodeJpg(picture, quality: 85));
    }
  });

  tearDown(() {
    photos.deleteSync(recursive: true);
    imageCache.clear();
    imageCache.clearLiveImages();
  });

  Possession row(int index) => Possession(
    clientId: 'thing-$index',
    householdId: 'home',
    name: 'Gegenstand $index',
    room: 'Wohnzimmer',
    photoPath: '${photos.path}/photo-$index.jpg',
    updatedAt: DateTime.utc(2026, 9, 18),
    dirty: false,
  );

  testWidgets('a list of photographed possessions stays within memory', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          possessionsProvider(
            'home',
          ).overrideWith(
            (ref) => Stream.value([for (var i = 0; i < 8; i++) row(i)]),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PossessionsScreen(householdId: 'home'),
        ),
      ),
    );
    // Decoding a real file is real asynchronous work; fake async never
    // gets there.
    await tester.runAsync(() async {
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await tester.pump();

    // Eight thumbnails at 48 by 48, even at triple pixel density, come to
    // well under two megabytes of pixels. Undecorated, these eight came to
    // 91.6 MB — Flutter's whole image cache holds 100 MB, so the ninth
    // photographed item began evicting the others and every rebuild
    // decoded JPEGs again.
    expect(
      imageCache.currentSizeBytes / (1024 * 1024),
      lessThan(2),
      reason: 'the stored picture is being decoded at its full 2000 pixels',
    );
  });
}
