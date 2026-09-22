import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qr/qr.dart';
import 'package:preppsuite_flutter/features/transfer/application/qr_chain.dart';

/// Showing data on one screen and filming it with another.
///
/// There is no back channel, so everything here has to survive the
/// receiver missing frames, seeing them out of order, seeing the same one
/// forty times, and being pointed at the wrong screen halfway through.
void main() {
  Uint8List bytes(String text) => utf8.encode(text);

  /// A payload of roughly the shape *and* the variety the app really
  /// sends.
  ///
  /// The variety matters: a thousand identical rows compress to nothing
  /// and would make every figure here flattering. Names, units and places
  /// are drawn from a spread, and the client ids are random, which is
  /// what they are in the app.
  Uint8List household(int items, {int seed = 1}) {
    const names = [
      'Haferflocken',
      'Passierte Tomaten',
      'Rapsöl, kaltgepresst',
      'Vollmilch H',
      'Linsen, braun',
      'Knäckebrot Roggen',
      'Kaffee, gemahlen',
      'Dosenpfirsiche',
      'Nudeln, Penne',
      'Zucker, weiß',
    ];
    const places = ['Keller', 'Speisekammer', 'Küche oben', 'Garage'];
    const units = ['kg', 'g', 'l', 'Stück', 'Packung'];
    final random = Random(seed);

    return utf8.encode(
      jsonEncode({
        'inventoryItems': [
          for (var index = 0; index < items; index++)
            {
              'clientId':
                  '${random.nextInt(0xffffffff).toRadixString(16)}-'
                  '${random.nextInt(0xffffffff).toRadixString(16)}',
              'householdId': 'household-1',
              'name':
                  '${names[random.nextInt(names.length)]} '
                  '${random.nextInt(900) + 100}',
              'category': 'Lebensmittel',
              'quantity': random.nextInt(40) / 4,
              'unit': units[random.nextInt(units.length)],
              'storageLocation': places[random.nextInt(places.length)],
              'updatedAt': 1789000000 + random.nextInt(900000),
              'dirty': false,
            },
        ],
      }),
    );
  }

  /// Feeds every frame to a receiver, in the given order.
  QrChainReceiver watch(List<String> frames) {
    final receiver = QrChainReceiver();
    for (final frame in frames) {
      receiver.take(frame);
    }
    return receiver;
  }

  group('cutting up', () {
    test('a small payload is one frame', () {
      final frames = qrChainFrames(bytes('Treffpunkt: vor der Garage'));

      expect(frames, hasLength(1));
      expect(frames.single, startsWith('PS1:'));
    });

    test('every frame says which one it is and how many there are', () {
      final frames = qrChainFrames(household(200), frameSize: 700);

      expect(frames.length, greaterThan(1));
      for (var index = 0; index < frames.length; index++) {
        final frame = QrChainFrame.parse(frames[index])!;
        expect(frame.index, index);
        expect(frame.total, frames.length);
      }
    });

    test('no frame is longer than asked for', () {
      // The whole point of the size: a denser code is a grey smudge to a
      // camera pointed at a screen across a table.
      final frames = qrChainFrames(household(300), frameSize: 400);

      for (final frame in frames) {
        expect(frame.length, lessThanOrEqualTo(400 + 32));
      }
    });

    test('the app\'s own data compresses hard', () {
      // Why it is worth compressing at all: this is what decides whether
      // somebody holds a phone up for ten seconds or ninety.
      final payload = household(200);
      final frames = qrChainFrames(payload);
      final sent = frames.fold<int>(0, (sum, frame) => sum + frame.length);

      expect(sent, lessThan(payload.length ~/ 2));
    });

    test('nothing to send is refused rather than sent as nothing', () {
      expect(() => qrChainFrames(Uint8List(0)), throwsArgumentError);
    });
  });

  group('putting back together', () {
    test('in order', () {
      final payload = household(50);
      final receiver = watch(qrChainFrames(payload));

      expect(receiver.isComplete, isTrue);
      expect(receiver.payload(), payload);
    });

    test('out of order', () {
      // A camera catches whatever is in front of it when it looks.
      final payload = household(50);
      final frames = qrChainFrames(payload)..shuffle(Random(7));

      expect(watch(frames).payload(), payload);
    });

    test('with frames missed and caught on the next pass round', () {
      // The reason the sender loops for ever instead of stopping.
      final payload = household(80);
      final frames = qrChainFrames(payload);

      final firstPass = [
        for (var index = 0; index < frames.length; index++)
          if (index.isEven) frames[index],
      ];
      final receiver = watch(firstPass);
      expect(receiver.isComplete, isFalse);
      expect(receiver.missing, isNotEmpty);

      // Second time round it sees the rest.
      for (final frame in frames) {
        receiver.take(frame);
      }

      expect(receiver.isComplete, isTrue);
      expect(receiver.payload(), payload);
    });

    test('the same frame forty times over counts once', () {
      final payload = household(30);
      final frames = qrChainFrames(payload);

      final receiver = QrChainReceiver();
      for (var pass = 0; pass < 40; pass++) {
        receiver.take(frames.first);
      }

      expect(receiver.received, 1);
      expect(receiver.take(frames.first), isFalse, reason: 'not new');
    });

    test('progress runs from nothing to one', () {
      final frames = qrChainFrames(household(80));
      final receiver = QrChainReceiver();

      expect(receiver.progress, 0);
      receiver.take(frames.first);
      expect(receiver.progress, greaterThan(0));
      expect(receiver.progress, lessThan(1));

      for (final frame in frames) {
        receiver.take(frame);
      }
      expect(receiver.progress, 1);
    });

    test('nothing comes out until everything is in', () {
      final frames = qrChainFrames(household(80));
      final receiver = watch(frames.take(frames.length - 1).toList());

      expect(receiver.payload(), isNull);
    });
  });

  group('what the camera should not be fooled by', () {
    test('a barcode off a tin is not a frame', () {
      final receiver = QrChainReceiver();

      expect(receiver.take('4006381333931'), isFalse);
      expect(receiver.take('https://example.org'), isFalse);
      expect(receiver.take('PS1:broken'), isFalse);
      expect(receiver.take('PS1:abc:x:3:data'), isFalse);
      expect(
        receiver.take('PS1:abc:5:3:data'),
        isFalse,
        reason: 'out of range',
      );
      expect(receiver.received, 0);
    });

    test('being pointed at a different transfer starts over', () {
      // Half of one payload and half of another reassembles into rubbish.
      // Better to lose the progress than to hand back something wrong.
      final first = qrChainFrames(household(400));
      final second = qrChainFrames(household(400, seed: 2));

      final receiver = QrChainReceiver();
      for (final frame in first.take(3)) {
        receiver.take(frame);
      }
      expect(receiver.received, 3);

      receiver.take(second.first);
      expect(receiver.received, 1, reason: 'the first transfer was dropped');

      for (final frame in second) {
        receiver.take(frame);
      }
      expect(receiver.isComplete, isTrue);
    });

    test('a corrupted frame is caught rather than handed over', () {
      final frames = qrChainFrames(household(400));
      expect(frames.length, greaterThan(1), reason: 'needs a frame to spoil');
      final receiver = QrChainReceiver();

      for (var index = 0; index < frames.length; index++) {
        final frame = QrChainFrame.parse(frames[index])!;
        // One frame arrives with its payload mangled but its header
        // intact — what a misread with error correction that *almost*
        // held would look like.
        final data = index == 1 ? 'AAAA${frame.data.substring(4)}' : frame.data;
        receiver.take(
          'PS1:${frame.checksum}:${frame.index}:${frame.total}:$data',
        );
      }

      expect(receiver.isComplete, isTrue);
      expect(() => receiver.payload(), throwsA(isA<QrChainException>()));
    });
  });

  test('a realistic household is a handful of frames, not a hundred', () {
    // 147 checklist items and 200 inventory rows is a real household; at
    // a couple of frames a second this has to be seconds, not minutes.
    final frames = qrChainFrames(household(200));

    expect(frames.length, lessThan(20));
  });

  group('how dense a frame comes out', () {
    // The figure that decides whether any of this works at all. A code
    // the camera cannot read is not a slow transfer, it is a transfer
    // that sits at "1 von 18" for ever — so the density is pinned here
    // rather than left to a comment.
    //
    // It had drifted once already: the size was chosen for the payload
    // while the header rode along unaccounted for, so a frame meant for
    // version 20 came out at version 22.
    int versionOf(String frame) => QrCode.fromData(
      data: frame,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    ).typeNumber;

    test('a full frame stays inside version 20', () {
      // Random bytes on purpose: the chain gzips before it cuts, and a
      // repeating payload compresses to a single frame that proves
      // nothing about a full one.
      final noise = Random(20260922);
      final frames = qrChainFrames(
        Uint8List.fromList(
          List.generate(30000, (_) => noise.nextInt(256)),
        ),
      );

      expect(frames.length, greaterThan(20), reason: 'several full frames');
      for (final frame in frames) {
        expect(
          versionOf(frame),
          lessThanOrEqualTo(20),
          reason: '${frame.length} Zeichen',
        );
      }
    });

    test('and the header is counted, not hoped over', () {
      // The mistake itself: the payload is the size, the frame is longer.
      final noise = Random(1);
      final frames = qrChainFrames(
        Uint8List.fromList(List.generate(9000, (_) => noise.nextInt(256))),
      );

      expect(
        frames.first.length,
        greaterThan(qrChainFrameSize),
        reason: 'the header is really there',
      );
      expect(frames.first.length, lessThanOrEqualTo(666));
    });
  });
}
