/// The translation models on this device (#182).
///
/// One folder per direction under the app's own support directory, the
/// three files and a manifest beside them. The manifest is written last,
/// after every file has been checked against Mozilla's SHA-256: a folder
/// without one is a download that did not finish, and is never handed to
/// the engine. A model is about 20 to 37 MB a direction and can be fetched
/// again, so it is in no backup, like a downloaded map.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../core/app_database_directory.dart';
import '../../downloads/application/archive_downloader.dart';
import '../../phrasebook/application/phrasebook.dart' show PhraseLanguage;
import 'translator_catalogue.dart';

/// A direction on this device, ready for the engine.
class InstalledTranslatorPack {
  const InstalledTranslatorPack({
    required this.direction,
    required this.version,
    required this.size,
    required this.modelPath,
    required this.lexPath,
    required this.vocabPath,
  });

  final TranslatorDirection direction;
  final String version;
  final int size;
  final String modelPath;
  final String lexPath;
  final String vocabPath;
}

/// How far installing a direction has got, over all its files.
class TranslatorInstallProgress {
  const TranslatorInstallProgress({
    required this.received,
    required this.total,
  });

  final int received;
  final int total;

  double get fraction => total <= 0 ? 0 : (received / total).clamp(0.0, 1.0);
}

class TranslatorStore {
  TranslatorStore({this.root, this.httpClient});

  /// Where the packs live; the app's support directory unless a test
  /// says otherwise.
  final Directory? root;
  final http.Client? httpClient;

  static const _manifestName = 'manifest.json';

  Future<Directory> _directory() async =>
      root ??
      Directory(p.join((await appSupportDirectory()).path, 'translator'));

  Future<Directory> _folderFor(TranslatorDirection direction) async =>
      Directory(p.join((await _directory()).path, direction.code));

  /// Every complete direction on this device.
  Future<List<InstalledTranslatorPack>> installed() async {
    final root = await _directory();
    if (!await root.exists()) return const [];
    final packs = <InstalledTranslatorPack>[];
    await for (final entry in root.list()) {
      if (entry is! Directory) continue;
      final pack = await _read(entry);
      if (pack != null) packs.add(pack);
    }
    packs.sort((a, b) => a.direction.code.compareTo(b.direction.code));
    return packs;
  }

  /// [direction] if it is complete on this device.
  Future<InstalledTranslatorPack?> find(TranslatorDirection direction) async =>
      _read(await _folderFor(direction));

  Future<InstalledTranslatorPack?> _read(Directory folder) async {
    final manifest = File(p.join(folder.path, _manifestName));
    if (!await manifest.exists()) return null;
    try {
      final json = jsonDecode(await manifest.readAsString()) as Map;
      final languages = PhraseLanguage.values.asNameMap();
      final from = languages[json['from']];
      final to = languages[json['to']];
      final files = (json['files'] as Map).cast<String, String>();
      String path(String kind) => p.join(folder.path, p.basename(files[kind]!));
      final pack = InstalledTranslatorPack(
        direction: TranslatorDirection(from!, to!),
        version: json['version'] as String,
        size: json['size'] as int,
        modelPath: path('model'),
        lexPath: path('lex'),
        vocabPath: path('vocab'),
      );
      for (final file in [pack.modelPath, pack.lexPath, pack.vocabPath]) {
        if (!await File(file).exists()) return null;
      }
      return pack;
    } on Object {
      // A manifest that does not read is a folder that is not a pack.
      return null;
    }
  }

  /// Fetches [pack], checks every file and only then writes the manifest.
  ///
  /// Each file resumes where an earlier attempt stopped, as maps and
  /// archives do. A file whose checksum does not match is deleted, not
  /// kept under its name -- the same rule as for a video pack.
  Stream<TranslatorInstallProgress> install(TranslatorPack pack) async* {
    final folder = await _folderFor(pack.direction);
    await folder.create(recursive: true);
    final manifest = File(p.join(folder.path, _manifestName));
    if (await manifest.exists()) await manifest.delete();

    final downloader = ArchiveDownloader(httpClient: httpClient);
    var done = 0;
    for (final file in pack.files) {
      final target = File(p.join(folder.path, file.name));
      if (!await target.exists() ||
          await target.length() != file.size ||
          await _sha256(target) != file.sha256) {
        if (await target.exists()) await target.delete();
        await for (final progress in downloader.download(
          url: file.url,
          targetPath: target.path,
          estimatedLength: file.size,
        )) {
          yield TranslatorInstallProgress(
            received: done + progress.received,
            total: pack.size,
          );
        }
        if (await _sha256(target) != file.sha256) {
          await target.delete();
          throw TranslatorStoreException(
            '${file.name} does not match its checksum',
          );
        }
      }
      done += file.size;
      yield TranslatorInstallProgress(received: done, total: pack.size);
    }

    await manifest.writeAsString(
      jsonEncode({
        'from': pack.direction.from.name,
        'to': pack.direction.to.name,
        'version': pack.version,
        'size': pack.size,
        'files': {for (final file in pack.files) file.kind.name: file.name},
      }),
    );
  }

  /// Removes [direction] from this device, files and all.
  Future<void> remove(TranslatorDirection direction) async {
    final folder = await _folderFor(direction);
    if (await folder.exists()) await folder.delete(recursive: true);
  }

  static Future<String> _sha256(File file) async {
    final sink = Sha256().newHashSink();
    await for (final chunk in file.openRead()) {
      sink.add(chunk);
    }
    sink.close();
    final hash = await sink.hash();
    return [
      for (final byte in hash.bytes) byte.toRadixString(16).padLeft(2, '0'),
    ].join();
  }
}

class TranslatorStoreException implements Exception {
  const TranslatorStoreException(this.message);

  final String message;

  @override
  String toString() => 'TranslatorStoreException: $message';
}
