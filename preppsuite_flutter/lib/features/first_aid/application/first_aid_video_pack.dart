/// Videos for the first aid guides, kept out of the app.
///
/// The app itself ships no film at all, on purpose. Ten two-minute clips
/// at a watchable resolution are two to three hundred megabytes against an
/// app that is thirty-six, and every household would carry them whether or
/// not it ever opened one. Worse, every German first aid video worth
/// having is somebody's copyright — the aid organisations' material is all
/// rights reserved — so a bundled set could only be assembled out of what
/// happens to be freely licensed, which is thin.
///
/// So a pack is a separate download, described by a small manifest, and
/// the manifest names the licence and the credit of every clip in it. A
/// pack can also arrive as a single zip on a memory stick, which is the
/// path that works in the situation this whole app is about.
///
/// Nothing here is required for a guide to be usable: the text, the
/// numbers and the drawings are the instruction, and the film is an extra
/// for the evening somebody sits down to learn it properly.
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;

/// What a manifest this version understands says at the top.
///
/// Checked rather than assumed, so a pack built for a later version is
/// refused with a sentence instead of half-read.
const firstAidPackFormat = 1;

/// The manifest's name inside a pack folder and inside a pack zip.
const firstAidPackFileName = 'paket.json';

/// One clip.
class FirstAidVideo {
  const FirstAidVideo({
    required this.id,
    required this.guideId,
    required this.title,
    required this.fileName,
    required this.credit,
    required this.licence,
    this.url,
    this.bytes,
    this.sha256,
    this.seconds,
  });

  /// Unique within a pack.
  final String id;

  /// Which guide it belongs to — a [FirstAidGuide.id]. A video naming a
  /// guide this version has never heard of is kept and simply never
  /// shown; see `firstAidGuideIds`.
  final String guideId;

  final String title;

  /// The file's name inside the pack folder. Never a path: a manifest is
  /// a downloaded document, and one that could name `../../` would be a
  /// way to write anywhere on the disk.
  final String fileName;

  /// Who made it. Shown under the video, because most free licences
  /// require it and because it is how a viewer judges what they are
  /// watching.
  final String credit;

  /// The licence, spelled as its name — `CC BY-SA 4.0`, `CC0`.
  final String licence;

  /// Where to fetch it. Absent in a pack that came off a memory stick,
  /// where the file is simply there.
  final Uri? url;

  /// The exact length in bytes, which is checked after a download.
  final int? bytes;

  /// Lower-case hex. Optional, and checked when present.
  final String? sha256;

  /// Roughly how long it runs, for the list.
  final int? seconds;

  Duration? get length => seconds == null ? null : Duration(seconds: seconds!);

  /// Whether [fileName] is a plain name that stays inside the folder.
  bool get hasSafeFileName =>
      fileName.isNotEmpty &&
      fileName == p.basename(fileName) &&
      fileName != '.' &&
      fileName != '..';

  static FirstAidVideo _fromJson(Map<String, Object?> json) {
    final url = json['url'];
    return FirstAidVideo(
      id: json['id']! as String,
      guideId: json['guide']! as String,
      title: json['title']! as String,
      fileName: json['file']! as String,
      credit: json['credit'] as String? ?? '',
      licence: json['licence'] as String? ?? '',
      url: url is String && url.isNotEmpty ? Uri.parse(url) : null,
      bytes: (json['bytes'] as num?)?.toInt(),
      sha256: (json['sha256'] as String?)?.toLowerCase(),
      seconds: (json['seconds'] as num?)?.toInt(),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'guide': guideId,
    'title': title,
    'file': fileName,
    'credit': credit,
    'licence': licence,
    if (url != null) 'url': url.toString(),
    if (bytes != null) 'bytes': bytes,
    if (sha256 != null) 'sha256': sha256,
    if (seconds != null) 'seconds': seconds,
  };
}

/// A described set of clips.
class FirstAidVideoPack {
  const FirstAidVideoPack({
    required this.name,
    required this.language,
    required this.videos,
    this.baseUrl,
  });

  final String name;

  /// A language tag: `de`, `en`.
  final String language;

  final List<FirstAidVideo> videos;

  /// Resolves a video's relative `url` against this, so a manifest does
  /// not repeat the same host on every line.
  final Uri? baseUrl;

  int get totalBytes => videos.fold(0, (sum, v) => sum + (v.bytes ?? 0));

  /// Everything in the pack for one guide, in manifest order.
  List<FirstAidVideo> forGuide(String guideId) => [
    for (final video in videos)
      if (video.guideId == guideId) video,
  ];

  /// Where [video] is actually fetched from.
  Uri? resolve(FirstAidVideo video) {
    final url = video.url;
    if (url == null) return null;
    if (url.hasScheme) return url;
    final base = baseUrl;
    return base?.resolveUri(url);
  }

  /// Reads a manifest.
  ///
  /// Throws [FormatException] with a sentence a person can read, because
  /// what comes back from a URL somebody typed is as likely to be a login
  /// page as a manifest.
  static FirstAidVideoPack parse(String source, {Uri? from}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const FormatException('That is not a pack description.');
    }
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('That is not a pack description.');
    }

    final format = (decoded['format'] as num?)?.toInt();
    if (format == null) {
      throw const FormatException('That is not a pack description.');
    }
    if (format > firstAidPackFormat) {
      throw FormatException(
        'This pack needs a newer version of the app (format $format).',
      );
    }

    final rawVideos = decoded['videos'];
    if (rawVideos is! List) {
      throw const FormatException('The pack description lists no videos.');
    }

    final videos = <FirstAidVideo>[];
    for (final entry in rawVideos) {
      if (entry is! Map<String, Object?>) continue;
      try {
        final video = FirstAidVideo._fromJson(entry);
        // A name that is a path is dropped rather than refused: one bad
        // line must not cost the household the whole pack.
        if (video.hasSafeFileName) videos.add(video);
      } on Object {
        continue;
      }
    }
    if (videos.isEmpty) {
      throw const FormatException('The pack description lists no videos.');
    }

    final base = decoded['baseUrl'];
    return FirstAidVideoPack(
      name: decoded['name'] as String? ?? 'Videos',
      language: decoded['language'] as String? ?? 'de',
      videos: videos,
      baseUrl: base is String && base.isNotEmpty ? Uri.parse(base) : from,
    );
  }

  String toJsonString() => const JsonEncoder.withIndent('  ').convert({
    'format': firstAidPackFormat,
    'name': name,
    'language': language,
    if (baseUrl != null) 'baseUrl': baseUrl.toString(),
    'videos': [for (final video in videos) video.toJson()],
  });
}

/// The pack on this device.
///
/// Lives in the ordinary download folder rather than in app-private
/// storage, for the same reason archives do: it is large, the household
/// may want to copy it to the next device by hand, and it must be
/// deletable without the app's help.
class FirstAidVideoLibrary {
  const FirstAidVideoLibrary(this.folder);

  /// The folder holding `paket.json` and the video files.
  final Directory folder;

  /// The pack folder inside a download folder.
  static Directory inside(Directory downloads) =>
      Directory(p.join(downloads.path, 'ErsteHilfe'));

  File get manifestFile => File(p.join(folder.path, firstAidPackFileName));

  File fileFor(FirstAidVideo video) =>
      File(p.join(folder.path, video.fileName));

  /// What is installed, or null when nothing is.
  ///
  /// A manifest that cannot be read reads as "nothing installed" rather
  /// than throwing: the screen must open either way, and the remedy —
  /// fetch the pack again — is the same.
  Future<FirstAidVideoPack?> installed() async {
    if (!await manifestFile.exists()) return null;
    try {
      return FirstAidVideoPack.parse(await manifestFile.readAsString());
    } on Object {
      return null;
    }
  }

  /// The videos whose files are actually on the disk.
  ///
  /// The manifest lists what a pack contains; this says what arrived. The
  /// two differ for as long as a download is unfinished, which on a slow
  /// connection is most of the time.
  Future<List<FirstAidVideo>> present(FirstAidVideoPack pack) async {
    final found = <FirstAidVideo>[];
    for (final video in pack.videos) {
      if (await fileFor(video).exists()) found.add(video);
    }
    return found;
  }

  Future<void> writeManifest(FirstAidVideoPack pack) async {
    await folder.create(recursive: true);
    await manifestFile.writeAsString(pack.toJsonString());
  }

  /// Checks a downloaded file against what the manifest promised.
  ///
  /// Returns null when it is sound, and otherwise a sentence saying what
  /// is wrong. The file is deleted in that case: a half-file kept under
  /// its final name is a file the app would later play.
  Future<String?> verify(FirstAidVideo video) async {
    final file = fileFor(video);
    if (!await file.exists()) return 'The file is not there.';

    final expected = video.bytes;
    if (expected != null && await file.length() != expected) {
      await file.delete();
      return 'The file is not the size the pack states.';
    }

    final digest = video.sha256;
    if (digest != null && digest.isNotEmpty) {
      final actual = await _sha256OfFile(file);
      if (actual != digest) {
        await file.delete();
        return 'The file does not match its checksum.';
      }
    }
    return null;
  }

  Future<void> remove(FirstAidVideo video) async {
    final file = fileFor(video);
    if (await file.exists()) await file.delete();
  }

  /// Everything: the files and the manifest.
  Future<void> removeAll() async {
    if (await folder.exists()) await folder.delete(recursive: true);
  }

  /// How much disk the installed files take.
  Future<int> bytesOnDisk() async {
    if (!await folder.exists()) return 0;
    var total = 0;
    await for (final entry in folder.list()) {
      if (entry is File) total += await entry.length();
    }
    return total;
  }

  /// Takes a pack out of a zip — the memory-stick path.
  ///
  /// Returns null when it worked, and otherwise a sentence. The zip is
  /// read as a stream and each entry written straight out, because a pack
  /// is hundreds of megabytes and decoding one into memory on a phone is
  /// how an app gets killed by the system mid-import.
  Future<String?> importZip(String zipPath) async {
    final input = InputFileStream(zipPath);
    try {
      final Archive archive;
      try {
        archive = ZipDecoder().decodeStream(input);
      } on Object {
        return 'That file is not a pack.';
      }
      // A file that is not a zip at all does not throw here: the decoder
      // looks for a central directory, does not find one, and hands back
      // an archive with nothing in it. Without this, a holiday photo that
      // somebody picked by mistake was answered with "that zip holds no
      // paket.json", which calls it a zip and sends them looking for the
      // wrong thing. An empty zip is not a pack either.
      if (archive.files.isEmpty) return 'That file is not a pack.';

      // The manifest first, so nothing is written for a zip that turns
      // out not to be a pack at all.
      ArchiveFile? manifest;
      for (final entry in archive.files) {
        if (entry.isFile && p.basename(entry.name) == firstAidPackFileName) {
          manifest = entry;
          break;
        }
      }
      if (manifest == null) {
        return 'That zip holds no $firstAidPackFileName.';
      }

      final FirstAidVideoPack pack;
      try {
        pack = FirstAidVideoPack.parse(
          utf8.decode(manifest.readBytes() ?? const [], allowMalformed: true),
        );
      } on FormatException catch (error) {
        return error.message;
      }

      await folder.create(recursive: true);
      final wanted = {for (final video in pack.videos) video.fileName};

      for (final entry in archive.files) {
        if (!entry.isFile) continue;
        // By basename and against the manifest's own list: an entry the
        // manifest does not mention is not written at all, which is what
        // keeps a crafted zip from putting a file anywhere it likes.
        final name = p.basename(entry.name);
        if (!wanted.contains(name)) continue;
        final output = OutputFileStream(p.join(folder.path, name));
        try {
          entry.writeContent(output);
        } finally {
          await output.close();
        }
      }

      await writeManifest(pack);
      return null;
    } finally {
      await input.close();
    }
  }

  static Future<String> _sha256OfFile(File file) async {
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
