import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:vector_tile/vector_tile.dart';

import '../../knowledge/application/personal_document_store.dart';
import '../../knowledge/application/personal_document_text.dart';
import '../../knowledge/application/zim_archive.dart';
import '../../knowledge/application/zim_store.dart';
import '../../maps/application/map_archive_access.dart';
import '../../maps/application/offline_map_store.dart';
import '../../maps/application/pmtiles_archive.dart';
import '../../translator/application/translator_engine.dart';
import '../../translator/application/translator_store.dart';

enum OfflineProbeKind { map, archive, document, translation, other }

enum OfflineProbeStatus { passed, failed, notChecked }

enum OfflineProbeReason {
  readable,
  missing,
  unsupported,
  unreadable,
  limit,
  timeout,
  cancelled,
  noSample,
}

class OfflineProbeResult {
  const OfflineProbeResult(this.kind, this.label, this.status, this.reason);
  final OfflineProbeKind kind;
  final String label;
  final OfflineProbeStatus status;
  final OfflineProbeReason reason;
}

class OfflineProbeControl {
  bool _cancelled = false;
  void Function()? _interrupt;
  bool get cancelled => _cancelled;
  void cancel() {
    _cancelled = true;
    _interrupt?.call();
  }
}

class OfflineProbeTarget {
  const OfflineProbeTarget(this.kind, this.label, this.check);
  final OfflineProbeKind kind;
  final String label;
  final Future<void> Function(OfflineProbeControl control) check;
}

class _NotChecked implements Exception {
  const _NotChecked(this.reason);
  final OfflineProbeReason reason;
}

/// Reads actual content, never a catalogue or a download. The HTTP guard is
/// scoped to this operation, so the app's unrelated warning poll is untouched.
/// OS file providers are outside Dart's network stack; the interface therefore
/// distinguishes a read test from a test made after disconnecting the network.
class OfflineProbe {
  const OfflineProbe({
    this.targets,
    this.timeout = const Duration(seconds: 20),
    this.maxTargets = 100,
  });

  final Future<List<OfflineProbeTarget>> Function()? targets;
  final Duration timeout;
  final int maxTargets;
  static const documentByteLimit = 32 * 1000 * 1000;

  Stream<OfflineProbeResult> run(OfflineProbeControl control) async* {
    final all = await HttpOverrides.runZoned(
      () => (targets ?? _targets)().timeout(timeout),
      createHttpClient: (_) => throw const SocketException('Offline probe'),
    );
    final count = math.max(0, maxTargets);
    for (final target in all.take(count)) {
      if (control.cancelled) {
        yield OfflineProbeResult(
          target.kind,
          target.label,
          OfflineProbeStatus.notChecked,
          OfflineProbeReason.cancelled,
        );
        continue;
      }
      OfflineProbeStatus status = OfflineProbeStatus.passed;
      OfflineProbeReason reason = OfflineProbeReason.readable;
      try {
        await HttpOverrides.runZoned(
          () => target.check(control).timeout(timeout),
          createHttpClient: (_) => throw const SocketException('Offline probe'),
        );
        if (control.cancelled) throw const PersonalDocumentCancelled();
      } on _NotChecked catch (error) {
        status = OfflineProbeStatus.notChecked;
        reason = error.reason;
      } on PersonalDocumentTooLarge {
        status = OfflineProbeStatus.notChecked;
        reason = OfflineProbeReason.limit;
      } on UnsupportedError {
        status = OfflineProbeStatus.notChecked;
        reason = OfflineProbeReason.unsupported;
      } on TimeoutException {
        status = OfflineProbeStatus.notChecked;
        reason = OfflineProbeReason.timeout;
        // A native read or translation cannot always be interrupted. Stop
        // here instead of accumulating more outstanding work after a timeout.
        control.cancel();
      } on PersonalDocumentCancelled {
        status = OfflineProbeStatus.notChecked;
        reason = OfflineProbeReason.cancelled;
      } on Object {
        status = OfflineProbeStatus.failed;
        reason = OfflineProbeReason.unreadable;
      }
      yield OfflineProbeResult(target.kind, target.label, status, reason);
    }
    if (all.length > count) {
      yield OfflineProbeResult(
        OfflineProbeKind.other,
        '${all.length - count}',
        OfflineProbeStatus.notChecked,
        OfflineProbeReason.limit,
      );
    }
  }

  Future<List<OfflineProbeTarget>> _targets() async {
    final result = <OfflineProbeTarget>[];
    OfflineProbeTarget absent(OfflineProbeKind kind) => OfflineProbeTarget(
      kind,
      '',
      (_) async => throw const _NotChecked(OfflineProbeReason.missing),
    );
    final map = await const OfflineMapStore().archive();
    result.add(
      map == null
          ? absent(OfflineProbeKind.map)
          : mapTarget(map.location, map.label),
    );
    final archives = (await const ZimStore().library()).archives;
    if (archives.isEmpty) result.add(absent(OfflineProbeKind.archive));
    for (final archive in archives) {
      result.add(archiveTarget(archive.location, archive.label));
    }
    final documents = await const PersonalDocumentStore().load();
    if (documents.isEmpty) result.add(absent(OfflineProbeKind.document));
    result.addAll(documents.map(documentTarget));
    if (!translatorAvailable) {
      result.add(
        OfflineProbeTarget(
          OfflineProbeKind.translation,
          '',
          (_) async => throw const _NotChecked(OfflineProbeReason.unsupported),
        ),
      );
    } else {
      final packs = await TranslatorStore().installed();
      if (packs.isEmpty) result.add(absent(OfflineProbeKind.translation));
      for (final pack in packs) {
        result.add(
          OfflineProbeTarget(OfflineProbeKind.translation, pack.direction.code, (
            _,
          ) async {
            // This tests loading and executing the saved model, not the quality
            // of its language output. It never asks for a missing model online.
            final value = await translateText('Test', [pack]);
            if (value.trim().isEmpty) {
              throw const FormatException('Empty translation');
            }
          }),
        );
      }
    }
    return result;
  }

  static OfflineProbeTarget documentTarget(PersonalDocument document) =>
      OfflineProbeTarget(OfflineProbeKind.document, document.label, (
        control,
      ) async {
        if (!const {
          'pdf',
          'epub',
          'md',
          'markdown',
        }.contains(document.extension)) {
          throw const _NotChecked(OfflineProbeReason.unsupported);
        }
        final job = PersonalDocumentTextJob.start(
          document,
          maxBytes: documentByteLimit,
          maxCharacters: 1024,
        );
        control._interrupt = job.cancel;
        try {
          await job.result;
        } finally {
          control._interrupt = null;
          job.cancel();
        }
      });

  static OfflineProbeTarget archiveTarget(String location, String label) =>
      OfflineProbeTarget(OfflineProbeKind.archive, label, (_) async {
        final source = _ProbeSource(await openMapArchive(location));
        ZimArchive? archive;
        try {
          archive = await ZimArchive.open(source);
          final page = await archive.mainPage();
          if (page == null) {
            throw const _NotChecked(OfflineProbeReason.noSample);
          }
          await archive.readBlob(page);
        } finally {
          if (archive != null) {
            await archive.close();
          } else {
            await source.close();
          }
        }
      });

  static OfflineProbeTarget mapTarget(String location, String label) =>
      OfflineProbeTarget(OfflineProbeKind.map, label, (_) async {
        final source = _ProbeSource(await openMapArchive(location));
        PmTilesArchive? archive;
        try {
          archive = await PmTilesArchive.open(source);
          if (archive.header.tileType != PmTilesType.mvt) {
            throw const FormatException('Not vector tiles');
          }
          await archive.metadata();
          final h = archive.header;
          final longitude = (h.minLongitude + h.maxLongitude) / 2;
          final latitude = ((h.minLatitude + h.maxLatitude) / 2).clamp(
            -85.0511,
            85.0511,
          );
          var sampled = false;
          for (final z in {h.minZoom, h.maxZoom}) {
            if (z < 0 || z > 24) throw const FormatException('Invalid zoom');
            final n = 1 << z;
            final x = ((longitude + 180) / 360 * n).floor().clamp(0, n - 1);
            final radians = latitude * math.pi / 180;
            final y =
                ((1 -
                            math.log(
                                  math.tan(radians) + 1 / math.cos(radians),
                                ) /
                                math.pi) /
                        2 *
                        n)
                    .floor()
                    .clamp(0, n - 1);
            final bytes = await archive.tile(z, x, y);
            if (bytes == null) continue;
            if (bytes.length > 2 * 1024 * 1024) {
              throw const _NotChecked(OfflineProbeReason.limit);
            }
            await Isolate.run(
              () => VectorTile.fromBytes(bytes: bytes).layers.length,
            );
            sampled = true;
          }
          if (!sampled) throw const _NotChecked(OfflineProbeReason.noSample);
        } finally {
          if (archive != null) {
            await archive.close();
          } else {
            await source.close();
          }
        }
      });
}

/// Bound reads as well as each format's decompression limits. A probe is a
/// sample and must not scan a multi-gigabyte archive from beginning to end.
class _ProbeSource implements ByteRangeSource {
  _ProbeSource(this.source);
  final ByteRangeSource source;
  int _read = 0;
  bool _closed = false;
  @override
  Future<Uint8List> read(int offset, int length) {
    _read += length;
    if (_read > 64 * 1024 * 1024) {
      throw const _NotChecked(OfflineProbeReason.limit);
    }
    return source.read(offset, length);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await source.close();
  }
}
