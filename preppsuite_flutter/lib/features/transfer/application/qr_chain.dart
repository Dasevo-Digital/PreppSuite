// Moves data between two devices by showing it and filming it.
//
// The one way left when there is no network, no shared folder and no
// pairing: one screen shows a run of QR codes, the other device's camera
// watches. It needs nothing but two devices that were already in the
// same room, which in this app's scenario is the case that matters —
// two people standing together, agreeing what the household holds.
//
// The codes are shown in a loop, over and over. That is what makes it
// work without a back channel: the receiver simply keeps watching until
// it has seen every frame, and a frame missed on one pass comes round
// again on the next. No handshake, no retransmission request, no
// protocol between the two devices at all — one talks, one listens.
//
// A frame looks like this, and is deliberately readable:
//
//     PS1:4f3a9c21:7:16:H4sIAAAA...
//     ^   ^        ^ ^  ^
//     |   |        | |  the payload, gzipped and base64
//     |   |        | how many frames there are altogether
//     |   |        which one this is, counting from zero
//     |   CRC32 of the whole payload, in hex
//     the format, so a later one can be told apart
//
// The checksum does double duty. It names the transfer, so frames from
// two different ones cannot be mixed into a nonsense result, and it is
// what proves the reassembly at the end.
//
// What this deliberately does NOT do is encrypt. The frames are plain
// pictures on a screen, and a household snapshot carries the emergency
// cards -- allergies, medication, conditions. Between two people standing
// together that is exactly right: they can see who is in the room, which
// is a better guarantee than any key exchange, and a passphrase between
// two people who are already talking is ceremony.
//
// It is also the reason this must never be turned into something that
// transmits. A QR code that can be filmed can only be filmed by someone
// present. The moment the same payload goes over a radio, a network or a
// file, that stops being true and it needs the folder's encryption --
// see `folder_crypto.dart`.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart' show GZipEncoder, GZipDecoder, getCrc32;

/// The marker every frame starts with.
const qrChainPrefix = 'PS1';

/// How many characters of payload go in one frame.
///
/// Not the maximum a QR code can hold — that is 2953 bytes, and a code
/// that dense is a grey smudge to a phone camera pointed at a screen
/// across a table. 700 lands around version 20 at medium error
/// correction, which stays legible at arm's length, and the cost is only
/// more frames in the loop.
const qrChainFrameSize = 700;

/// Cuts [payload] into frames to be shown one after another.
///
/// Compressed first: the app's own data is JSON, which halves.
List<String> qrChainFrames(
  Uint8List payload, {
  int frameSize = qrChainFrameSize,
}) {
  if (payload.isEmpty) {
    throw ArgumentError.value(payload, 'payload', 'nothing to send');
  }

  final packed = base64Url.encode(GZipEncoder().encode(payload));
  final checksum = getCrc32(payload).toRadixString(16).padLeft(8, '0');

  final total = (packed.length / frameSize).ceil();
  return [
    for (var index = 0; index < total; index++)
      '$qrChainPrefix:$checksum:$index:$total:'
          '${packed.substring(index * frameSize, ((index + 1) * frameSize).clamp(0, packed.length))}',
  ];
}

/// One frame, taken apart.
class QrChainFrame {
  const QrChainFrame({
    required this.checksum,
    required this.index,
    required this.total,
    required this.data,
  });

  final String checksum;
  final int index;
  final int total;
  final String data;

  /// Reads a frame, or null if this is not one of ours.
  ///
  /// Null and not an exception: the camera sees whatever is in front of
  /// it, including the barcode on a tin, and that is not an error worth
  /// reporting.
  static QrChainFrame? parse(String text) {
    final parts = text.split(':');
    if (parts.length < 5 || parts[0] != qrChainPrefix) return null;

    final index = int.tryParse(parts[2]);
    final total = int.tryParse(parts[3]);
    if (index == null || total == null) return null;
    if (total < 1 || index < 0 || index >= total) return null;

    return QrChainFrame(
      checksum: parts[1],
      index: index,
      total: total,
      // Rejoined rather than taken as parts[4]: base64url has no colon in
      // it, but a later format might, and losing the tail silently is the
      // kind of bug that only shows up on long payloads.
      data: parts.sublist(4).join(':'),
    );
  }
}

/// Collects frames until the whole payload is there.
///
/// Deliberately forgiving. Frames arrive in whatever order the camera
/// happens to catch them, the same one arrives many times over, and a
/// frame from a different transfer may turn up if somebody points the
/// camera at another screen. Only the last of those is worth reacting
/// to, and it is: a new checksum starts over rather than corrupting what
/// is already collected.
class QrChainReceiver {
  final _frames = <int, String>{};
  String? _checksum;
  int? _total;

  /// The transfer currently being collected, if any has started.
  String? get checksum => _checksum;

  int get received => _frames.length;
  int? get expected => _total;

  bool get isComplete => _total != null && _frames.length == _total;

  /// Between 0 and 1, for something to show while it runs.
  double get progress {
    final total = _total;
    if (total == null || total == 0) return 0;
    return _frames.length / total;
  }

  /// Takes what the camera read. Returns true if this frame was new.
  bool take(String text) {
    final frame = QrChainFrame.parse(text);
    if (frame == null) return false;

    // A different transfer means the camera is looking at another
    // screen, or the sender was restarted with different data. Starting
    // over is the only honest answer: half of one payload and half of
    // another reassembles into rubbish that the checksum would then
    // reject anyway, after wasting the person's time.
    if (_checksum != null && frame.checksum != _checksum) {
      _frames.clear();
    }
    _checksum = frame.checksum;
    _total = frame.total;

    if (_frames.containsKey(frame.index)) return false;
    _frames[frame.index] = frame.data;
    return true;
  }

  /// Which frames are still missing, so the screen can say so.
  List<int> get missing {
    final total = _total;
    if (total == null) return const [];
    return [
      for (var index = 0; index < total; index++)
        if (!_frames.containsKey(index)) index,
    ];
  }

  /// The payload, once every frame is in and the checksum agrees.
  ///
  /// Null while incomplete. Throws [QrChainException] when everything
  /// arrived and does not add up — which is worth saying out loud rather
  /// than handing back data nobody should trust.
  Uint8List? payload() {
    if (!isComplete) return null;

    final packed = StringBuffer();
    for (var index = 0; index < _total!; index++) {
      packed.write(_frames[index]);
    }

    final Uint8List bytes;
    try {
      bytes = Uint8List.fromList(
        GZipDecoder().decodeBytes(base64Url.decode(packed.toString())),
      );
    } on Object {
      throw const QrChainException('the frames did not unpack');
    }

    final checksum = getCrc32(bytes).toRadixString(16).padLeft(8, '0');
    if (checksum != _checksum) {
      throw const QrChainException('the checksum does not match');
    }
    return bytes;
  }

  void reset() {
    _frames.clear();
    _checksum = null;
    _total = null;
  }
}

class QrChainException implements Exception {
  const QrChainException(this.message);

  final String message;

  @override
  String toString() => 'QrChainException: $message';
}
