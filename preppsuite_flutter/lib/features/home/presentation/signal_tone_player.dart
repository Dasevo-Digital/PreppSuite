import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/distress_signal.dart';
import '../application/signal_tone.dart';

/// Sounds a [SignalRhythm] in step with the light that shows it (#188).
///
/// [prepare] renders one turn and has it ready before the lamp starts, so
/// the first tone and the first flash begin together; [follow] is called
/// from the same ticker that asks the rhythm whether the lamp is lit, and
/// starts the file again at the top of every turn. Anything the platform
/// refuses -- no audio device, no GStreamer on Linux, a plugin that is
/// not there -- turns [available] false and the light goes on alone, as
/// the compression pacer does it.
class SignalTonePlayer {
  AudioPlayer? _player;
  File? _file;
  Duration _period = Duration.zero;
  var _turn = -1;

  /// False once sound has failed on this device.
  bool available = true;

  /// How long loading may take before the lamp starts without sound. A
  /// player that never answers -- a Linux session whose GStreamer hangs,
  /// a plugin missing its other half -- must not hold the signal back.
  static const prepareTimeout = Duration(seconds: 3);

  /// Renders [rhythm] and loads it. Returns whether it is ready.
  Future<bool> prepare(SignalRhythm rhythm, {required double hertz}) async {
    await stop();
    _period = rhythm.period;
    if (_period <= Duration.zero) return false;
    try {
      return await _load(rhythm, hertz).timeout(prepareTimeout);
    } on Object {
      available = false;
      return false;
    }
  }

  Future<bool> _load(SignalRhythm rhythm, double hertz) async {
    final bytes = signalToneWav(rhythm, hertz: hertz);
    // A file of our own with its extension, rather than the plugin's
    // bytes source, which on Apple and Linux writes a file without one
    // and leaves the player to guess the format.
    //
    // Named after what it holds, so a player that caches by path never
    // plays the previous message.
    final directory = await getTemporaryDirectory();
    final name = Object.hash(
      hertz,
      Object.hashAll(rhythm.spans),
    ).toUnsigned(32).toRadixString(16);
    final file = File(p.join(directory.path, 'preppsuite-signal-$name.wav'));
    await file.writeAsBytes(bytes, flush: true);
    final previous = _file;
    _file = file;
    if (previous != null && previous.path != file.path) {
      unawaited(previous.delete().then((_) {}, onError: (Object _) {}));
    }
    final player = _player ??= AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(DeviceFileSource(file.path));
    return true;
  }

  /// Starts the turn [elapsed] falls in, if it has not been started yet.
  void follow(Duration elapsed) {
    final player = _player;
    if (player == null || !available || _period <= Duration.zero) return;
    final turn = elapsed.inMicroseconds ~/ _period.inMicroseconds;
    if (turn == _turn) return;
    _turn = turn;
    unawaited(_restart(player));
  }

  Future<void> _restart(AudioPlayer player) async {
    try {
      await player.seek(Duration.zero);
      await player.resume();
    } on Object {
      available = false;
    }
  }

  Future<void> stop() async {
    _turn = -1;
    try {
      await _player?.stop();
    } on Object {
      // Nothing was playing.
    }
  }

  Future<void> dispose() async {
    _turn = -1;
    final player = _player;
    _player = null;
    try {
      await player?.dispose();
    } on Object {
      // Already gone.
    }
    final file = _file;
    _file = null;
    unawaited(file?.delete().then((_) {}, onError: (Object _) {}));
  }
}

/// Whether the signals sound as well as flash: one choice for the
/// distress signal and the Morse lamp, remembered between visits.
class SignalToneSetting {
  const SignalToneSetting();

  static const _key = 'signalToneOn';

  Future<bool> load() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_key) ?? false;
    } on Object {
      return false;
    }
  }

  Future<void> save(bool on) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, on);
    } on Object {
      // Forgotten next time; the switch still works now.
    }
  }
}
