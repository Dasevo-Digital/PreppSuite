import 'dart:io';

import 'package:flutter/foundation.dart';

/// What went wrong on this device, kept on this device (#141).
///
/// The app has no server and sends nothing anywhere, so an error that a
/// person only half saw was gone for good: a grey patch on one screen, a
/// background poll that failed in the night. This writes each one into a
/// small text file in the app's own folder, which the settings show and
/// let the person copy or share themselves. Nothing leaves the device
/// unless they send it.
///
/// What goes in is the error and where in the code it happened -- not the
/// household: the home folder is cut out of paths, and the stack is kept
/// to the frames that say which part of the app it was.
class ErrorLog {
  ErrorLog._();

  static final instance = ErrorLog._();

  /// A log of its own, for tests.
  @visibleForTesting
  factory ErrorLog.forTesting() => ErrorLog._();

  /// About fifty entries; the oldest go first.
  static const maxBytes = 64 * 1024;
  static const _fileName = 'fehlerprotokoll.txt';
  static const _stackLines = 12;

  File? _file;
  final _early = <String>[];

  /// Called once the app's own folder is known. Entries recorded before
  /// that are written now.
  void attach(Directory directory) {
    _file = File('${directory.path}${Platform.pathSeparator}$_fileName');
    if (_early.isNotEmpty) {
      _early.forEach(_append);
      _early.clear();
    }
  }

  /// Records [error]. Never throws: it runs inside the error handlers, and
  /// an error log that fails must not become the next error.
  void record(Object error, StackTrace? stack, {String? context}) {
    try {
      final entry = format(
        error,
        stack,
        context: context,
        at: DateTime.now(),
        home: _home(),
      );
      if (_file == null) {
        _early.add(entry);
      } else {
        _append(entry);
      }
    } on Object {
      // Nowhere left to say it.
    }
  }

  /// The log as written, or an empty string.
  Future<String> read() async {
    final file = _file;
    if (file == null || !await file.exists()) return _early.join();
    return file.readAsString();
  }

  /// How many entries there are.
  Future<int> count() async =>
      RegExp(r'^=== ', multiLine: true).allMatches(await read()).length;

  Future<void> clear() async {
    _early.clear();
    final file = _file;
    if (file != null && await file.exists()) await file.delete();
  }

  void _append(String entry) {
    final file = _file!;
    var text = file.existsSync() ? file.readAsStringSync() : '';
    text += entry;
    // Cut at the start of an entry, so what is left reads whole.
    while (text.length > maxBytes) {
      final next = text.indexOf('\n=== ', 1);
      if (next < 0) {
        text = text.substring(text.length - maxBytes);
        break;
      }
      text = text.substring(next + 1);
    }
    file.writeAsStringSync(text, flush: true);
  }

  static String? _home() =>
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

  /// One entry: when, on what, which error, and the frames that say where.
  @visibleForTesting
  static String format(
    Object error,
    StackTrace? stack, {
    required DateTime at,
    String? context,
    String? home,
  }) {
    String clean(String text) =>
        home == null || home.isEmpty ? text : text.replaceAll(home, '~');
    final frames = stack == null
        ? const <String>[]
        : stack
              .toString()
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .take(_stackLines)
              .map(clean)
              .toList();
    return [
      '=== ${at.toUtc().toIso8601String()} · ${Platform.operatingSystem}'
          '${context == null ? '' : ' · $context'}',
      clean('${error.runtimeType}: $error'),
      ...frames,
      '',
    ].join('\n');
  }
}
