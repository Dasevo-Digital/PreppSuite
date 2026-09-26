import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart' show Brightness;
import 'package:vector_tile_renderer/vector_tile_renderer.dart'
    show Theme, ThemeLayerType, ThemeReader;
// The style data itself is not exported — only `ProvidedThemes`,
// which hands back a finished light `Theme`. Darkening needs the map
// it was read from. The alternative is copying sixty kilobytes of
// style into this repository, where it would go stale against the
// package silently; this way a changed style is a compile error.
// ignore: implementation_imports
import 'package:vector_tile_renderer/src/themes/light_theme.dart'
    show lightThemeData;

import 'dark_map_style.dart';
import 'map_label_language.dart';

import 'map_archive_access.dart';
import 'offline_map_store.dart';
import 'pmtiles_archive.dart';

/// Why an archive cannot be used. Null means it can.
enum OfflineMapProblem {
  /// Missing, unreadable, or not a PMTiles archive at all.
  unreadable,

  /// A PMTiles archive of raster images rather than vector tiles. Readable,
  /// but not by this renderer.
  notVectorTiles,

  /// Vector tiles in a schema the built-in style does not know. Protomaps'
  /// own extracts are the common case: same file format, different layer
  /// names, and the map would come out blank.
  unknownSchema,
}

class OfflineMapState {
  const OfflineMapState({this.label, this.archive, this.problem});

  /// What to call the chosen file in the settings screen.
  final String? label;

  /// Open and usable, or null.
  final PmTilesArchive? archive;

  final OfflineMapProblem? problem;

  /// Whether the map can be drawn from the file rather than the network.
  bool get isReady => archive != null;

  /// Whether the user picked something at all — a chosen-but-broken
  /// archive still has to be shown, or the error would have nowhere to go.
  bool get isConfigured => label != null;
}

/// The layer names the built-in style reads.
///
/// Two is enough to tell OpenMapTiles apart from the other schemas without
/// insisting on a particular version of it: an archive with roads and
/// water under these names will render, one without them will not.
const _requiredLayers = {'water', 'transportation'};

class OfflineMapController extends AsyncNotifier<OfflineMapState> {
  static const _store = OfflineMapStore();

  /// The archive currently being drawn from, held here rather than read
  /// back out of [state] so that closing it does not depend on the state
  /// still being readable.
  PmTilesArchive? _current;

  @override
  Future<OfflineMapState> build() async {
    ref.onDispose(_closeCurrent);

    final stored = await _store.archive();
    if (stored == null) return const OfflineMapState();

    final opened = await _open(stored.location, stored.label);
    _current = opened.archive;
    return opened;
  }

  /// Takes the archive at [location] into use, or explains why it cannot
  /// be.
  ///
  /// Returns the problem rather than throwing, because every one of them
  /// is something the user picked and can pick differently. A rejected
  /// file leaves a working archive exactly where it was — trying a second
  /// map and failing should not cost the first one.
  Future<OfflineMapProblem?> useArchive({
    required String location,
    required String label,
  }) async {
    final opened = await _open(location, label);
    if (opened.problem != null) return opened.problem;

    await _store.save(location: location, label: label);

    final previous = _current;
    _current = opened.archive;
    state = AsyncData(opened);
    if (previous != null) unawaited(previous.close());
    return null;
  }

  /// Goes back to the online map. The file is left where it is — the app
  /// never owned it.
  Future<void> forget() async {
    await _store.clear();
    _closeCurrent();
    state = const AsyncData(OfflineMapState());
  }

  void _closeCurrent() {
    final archive = _current;
    _current = null;
    if (archive != null) unawaited(archive.close());
  }

  /// Opens and vets an archive. On any problem it closes whatever it
  /// opened and hands back a state carrying the reason — nothing here
  /// touches what is already in use.
  Future<OfflineMapState> _open(String location, String label) async {
    PmTilesArchive? archive;
    try {
      archive = await PmTilesArchive.open(await openMapArchive(location));

      final problem = archive.header.tileType != PmTilesType.mvt
          ? OfflineMapProblem.notVectorTiles
          : await _schemaLooksRight(archive)
          ? null
          : OfflineMapProblem.unknownSchema;

      if (problem != null) {
        await archive.close();
        return OfflineMapState(label: label, problem: problem);
      }

      return OfflineMapState(label: label, archive: archive);
    } on Object {
      await archive?.close();
      return OfflineMapState(
        label: label,
        problem: OfflineMapProblem.unreadable,
      );
    }
  }

  /// Whether the archive's own layer list matches what the style reads.
  ///
  /// An archive that names no layers at all is accepted: the field is
  /// optional, and refusing a file for saying nothing would be worse than
  /// letting the user see whether it draws.
  Future<bool> _schemaLooksRight(PmTilesArchive archive) async {
    final layers = (await archive.metadata())['vector_layers'];
    if (layers is! List || layers.isEmpty) return true;

    final names = {
      for (final layer in layers)
        if (layer is Map && layer['id'] is String) layer['id'] as String,
    };
    return _requiredLayers.every(names.contains);
  }
}

final offlineMapProvider =
    AsyncNotifierProvider<OfflineMapController, OfflineMapState>(
      OfflineMapController.new,
    );

/// The map's look, built once per brightness.
///
/// The renderer ships an OpenMapTiles style derived from OSM Liberty, so
/// there is no style file to bundle or keep in step with anything. Its one
/// raster layer — a shaded relief from a web server — is dropped: this map
/// exists to work without a network, and a layer that reaches for one has
/// no business in it.
///
/// It ships exactly one style and it is light, which in a dark app made
/// the map a white rectangle — the brightest thing on the screen, on the
/// feature somebody opens at night in a power cut. The dark one is made
/// from it; see `dark_map_style.dart` for why it is turned rather than
/// written a second time.
///
/// A family rather than one provider, so each brightness is read and
/// parsed once and then kept. Reading the style is real work — sixty
/// kilobytes through `ThemeReader` — and doing it on every theme change
/// would be a stutter every time the sun goes down.
final mapThemeProvider = Provider.family<Theme, Brightness>((
  ref,
  brightness,
) {
  // Two passes over the same style: one for the light, one for the
  // language. Neither replaces the package's style, so a changed style
  // stays a compile error rather than a silent drift.
  final lit = brightness == Brightness.dark
      ? darkenMapStyle(lightThemeData()) as Map<String, dynamic>
      : lightThemeData();
  final data = germanMapLabels(lit) as Map<String, dynamic>;

  return ThemeReader()
      .read(data)
      .copyWith(
        types: {
          ThemeLayerType.background,
          ThemeLayerType.fill,
          ThemeLayerType.fillExtrusion,
          ThemeLayerType.line,
          ThemeLayerType.symbol,
        },
      );
});
