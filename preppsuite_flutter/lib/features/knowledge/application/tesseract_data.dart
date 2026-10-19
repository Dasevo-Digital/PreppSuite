/// Tesseract's data for more languages than the two the app ships (#205).
///
/// Android and Linux read photos and scans with Tesseract. The Android
/// package carries its German and English data; a sign in Russian or a
/// leaflet in Arabic needs that language's data, and even Spanish, Polish
/// or Turkish read better with their own -- German and English letters
/// alone turn a ł into an l. So the translator's "Text aus Foto" offers
/// the language's data before it reads.
///
/// * **Android** fetches it once, from the same source and tag as the
///   shipped files (`tesseract-ocr/tessdata_fast`, 4.1.0, Apache 2.0),
///   into the folder the engine reads, and checks it against the checksum
///   fixed below. A file that does not match is deleted.
/// * **Linux** uses the system's Tesseract, as it does for scans, and the
///   distribution's packages for it: the app says which one to install
///   (`tesseract-ocr-rus`) rather than keeping data of its own beside the
///   system's, which the command line could not read together.
///
/// Apple systems and Windows read with their own engines and need none of
/// this.
library;

import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../downloads/application/archive_downloader.dart';
import '../../phrasebook/application/phrasebook.dart' show PhraseLanguage;

/// One language's data, as `tessdata_fast` 4.1.0 has it.
class TesseractLanguage {
  const TesseractLanguage(this.code, this.size, this.sha256);

  /// Tesseract's own name for it, which is also the file's: `rus`.
  final String code;
  final int size;
  final String sha256;

  Uri get url => Uri.https(
    'raw.githubusercontent.com',
    '/tesseract-ocr/tessdata_fast/4.1.0/$code.traineddata',
  );

  /// The Debian and Ubuntu package that carries it.
  String get linuxPackage => 'tesseract-ocr-$code';
}

/// The languages whose data can be added, by phrasebook language. German
/// and English are shipped on Android and are not here.
///
/// Sizes and checksums of the 4.1.0 files, measured on 19.10.2026; the
/// shipped German and English files match their published checksums
/// from the same download, which is what says the source is the right one.
const tesseractLanguages = <PhraseLanguage, TesseractLanguage>{
  PhraseLanguage.es: TesseractLanguage(
    'spa',
    2294433,
    '6f2e04d02774a18f01bed44b1111f2cd7f3ba7ac9dc4373cd3f898a40ea6b464',
  ),
  PhraseLanguage.fr: TesseractLanguage(
    'fra',
    1130365,
    'ced037562e8c80c13122dece28dd477d399af80911a28791a66a63ac1e3445ca',
  ),
  PhraseLanguage.pl: TesseractLanguage(
    'pol',
    4765518,
    'c4476cdbc0e33d898d32345122b7be1cbf85ace15f920f06c7714756e1ef79b2',
  ),
  PhraseLanguage.tr: TesseractLanguage(
    'tur',
    4550554,
    '7393381111e1152420fc4092cb44eef4237580d21b92bf30d7d221aad192c6b7',
  ),
  PhraseLanguage.ru: TesseractLanguage(
    'rus',
    3861738,
    'e16e5e036cce1d9ec2b00063cf8b54472625b9e14d893a169e2b0dedeb4df225',
  ),
  PhraseLanguage.uk: TesseractLanguage(
    'ukr',
    3825102,
    'd59e53e2bded32f4445f124b4b00240fcac7e8044c003ab822ccb94f0b3db59b',
  ),
  PhraseLanguage.ar: TesseractLanguage(
    'ara',
    1432056,
    'e3206d3dc87fd50c24a0fb9f01838615911d25168f4e64415244b67d2bb3e729',
  ),
  PhraseLanguage.fa: TesseractLanguage(
    'fas',
    431500,
    'db1c0a91208aff00d3cf1ed2c1d23f76419afd5f024688b4f71adc3f2ce4a505',
  ),
};

/// Tesseract's name for the language of a BCP-47 tag, or null.
String? tesseractCodeForTag(String tag) => switch (tag.split('-').first) {
  'de' => 'deu',
  'en' => 'eng',
  'es' => 'spa',
  'fr' => 'fra',
  'pl' => 'pol',
  'tr' => 'tur',
  'ru' => 'rus',
  'uk' => 'ukr',
  'ar' => 'ara',
  'fa' => 'fas',
  _ => null,
};

/// [tags] as Tesseract takes them: `rus+eng`.
String tesseractLanguageString(List<String> tags) => {
  for (final tag in tags) ?tesseractCodeForTag(tag),
}.join('+');

/// Where this device keeps Tesseract's data, or the system's.
abstract interface class TesseractData {
  /// Whether [language] can be read with right now.
  Future<bool> has(TesseractLanguage language);
}

/// Android: data fetched into the folder the engine reads.
///
/// Only the engine knows that folder -- it is named after the data's
/// version, so that newer data lands beside older -- so it is asked for
/// over the text recognition channel rather than worked out here.
class DownloadedTesseractData implements TesseractData {
  DownloadedTesseractData({this.folder, this.httpClient});

  /// Injectable for tests; the engine's own folder otherwise.
  final Future<Directory> Function()? folder;
  final http.Client? httpClient;

  static const _channel = MethodChannel(
    'de.dasevo.preppsuite/text_recognition',
  );

  Future<Directory> _folder() async {
    if (folder case final folder?) return folder();
    final path = await _channel.invokeMethod<String>('tessdataPath');
    if (path == null) throw const TesseractDataException('no data folder');
    return Directory(path);
  }

  File _file(Directory folder, TesseractLanguage language) =>
      File('${folder.path}/${language.code}.traineddata');

  @override
  Future<bool> has(TesseractLanguage language) async {
    try {
      final file = _file(await _folder(), language);
      return await file.exists() && await file.length() == language.size;
    } on Object {
      return false;
    }
  }

  /// The languages fetched so far, by phrasebook language.
  Future<List<PhraseLanguage>> installed() async => [
    for (final MapEntry(:key, :value) in tesseractLanguages.entries)
      if (await has(value)) key,
  ];

  /// Fetches [language], reporting the bytes received, and checks it.
  ///
  /// The download goes to a `.part` file beside the target and is moved
  /// into place only once complete, so the engine never finds half a
  /// model under the real name.
  Stream<int> install(TesseractLanguage language) async* {
    final folder = await _folder();
    await folder.create(recursive: true);
    final target = _file(folder, language);
    if (await has(language)) {
      yield language.size;
      return;
    }
    if (await target.exists()) await target.delete();
    await for (final progress
        in ArchiveDownloader(httpClient: httpClient).download(
          url: language.url,
          targetPath: target.path,
          estimatedLength: language.size,
        )) {
      yield progress.received;
    }
    if (await target.length() != language.size ||
        await _sha256(target) != language.sha256) {
      await target.delete();
      throw TesseractDataException(
        '${language.code}.traineddata does not match its checksum',
      );
    }
    yield language.size;
  }

  Future<void> remove(TesseractLanguage language) async {
    final file = _file(await _folder(), language);
    if (await file.exists()) await file.delete();
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

/// Linux: the system's Tesseract and whatever language packages it has.
class SystemTesseractData implements TesseractData {
  const SystemTesseractData({this.executable = 'tesseract'});

  final String executable;

  @override
  Future<bool> has(TesseractLanguage language) async {
    try {
      final result = await Process.run(executable, ['--list-langs']);
      if (result.exitCode != 0) return false;
      return '${result.stdout}\n${result.stderr}'
          .split('\n')
          .map((line) => line.trim())
          .contains(language.code);
    } on ProcessException {
      return false;
    }
  }
}

class TesseractDataException implements Exception {
  const TesseractDataException(this.message);

  final String message;

  @override
  String toString() => 'TesseractDataException: $message';
}

/// The data behind Tesseract on this platform, or null where the system
/// reads with an engine of its own.
final tesseractDataProvider = Provider<TesseractData?>((ref) {
  if (kIsWeb) return null;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => DownloadedTesseractData(),
    TargetPlatform.linux => const SystemTesseractData(),
    _ => null,
  };
});

/// The languages fetched on this device, for the storage overview.
final installedTesseractLanguagesProvider =
    FutureProvider.autoDispose<List<PhraseLanguage>>((ref) async {
      final data = ref.watch(tesseractDataProvider);
      if (data is! DownloadedTesseractData) return const [];
      return data.installed();
    });
