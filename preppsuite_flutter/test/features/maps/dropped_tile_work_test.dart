import 'dart:async';

import 'package:drift/drift.dart' as drift show CancellationException;
import 'package:executor_lib/executor_lib.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/dropped_tile_work.dart';

int _square(int value) => value * value;

/// The map renderer drops tiles nobody looks at any more, and that is not
/// an error worth an entry in the log (#207).
void main() {
  test(
    'a tile job dropped and never awaited arrives as dropped work',
    () async {
      final caught = <Object>[];
      final arrived = Completer<void>();
      runZonedGuarded(
        () {
          // What the renderer does while it assembles a tile: start the
          // job, find the tile no longer wanted, and leave without waiting
          // for it.
          unawaited(
            QueueExecutor().submit(
              Job<int, int>(
                'tile 3/4/5',
                _square,
                3,
                cancelled: () => true,
                deduplicationKey: null,
              ),
            ),
          );
        },
        (error, _) {
          caught.add(error);
          if (!arrived.isCompleted) arrived.complete();
        },
      );
      await arrived.future.timeout(const Duration(seconds: 5));

      expect(caught, hasLength(1));
      // Exactly what the log showed a dozen times after a closed map.
      expect(
        '${caught.single.runtimeType}: ${caught.single}',
        'CancellationException: Cancelled',
      );
      expect(isDroppedTileWork(caught.single), isTrue);
    },
  );

  test('every other error still goes into the log', () {
    expect(isDroppedTileWork(StateError('kaputt')), isFalse);
    expect(isDroppedTileWork(TimeoutException('zu langsam')), isFalse);
    // Same name, other library: a cancelled query is not the map's.
    expect(isDroppedTileWork(const drift.CancellationException()), isFalse);
  });
}
