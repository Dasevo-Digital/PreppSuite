import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/continents.dart';
import 'package:preppsuite_flutter/features/maps/application/map_area_download.dart';
import 'package:preppsuite_flutter/features/maps/application/map_download_plan.dart';

/// Boxes as Nominatim gives them, so the numbers here are the numbers a
/// user actually gets.
MapArea box(double w, double s, double e, double n) => MapArea(
  minLongitude: w,
  minLatitude: s,
  maxLongitude: e,
  maxLatitude: n,
  maxZoom: 14,
);

final germany = box(5.8663, 47.2701, 15.0419, 55.0992);
final lowerSaxony = box(6.3459, 51.2951, 11.5981, 54.1378);
final hannover = box(9.6044, 52.3049, 9.9186, 52.4543);

void main() {
  group('a single ring', () {
    test('a town reaches the deepest level', () {
      final plan = staggeredPlan(
        rings: [MapDownloadRing(label: 'Hannover', box: hannover)],
      )!;

      // The world base and the town itself.
      expect(plan.steps, hasLength(2));
      expect(plan.maxZoom, 14);
      expect(plan.tileCount, lessThan(1000));
    });

    test('a country on its own has to give up detail', () {
      final plan = staggeredPlan(
        rings: [MapDownloadRing(label: 'Deutschland', box: germany)],
      )!;

      // 319,812 tiles at level 14; this is what fits instead.
      expect(plan.maxZoom, 13);
      expect(plan.tileCount, lessThanOrEqualTo(MapAreaDownloader.tileLimit));
    });
  });

  group('staggered', () {
    // The question this whole feature exists to answer: a country
    // completely offline, with street-level detail where it matters.
    test('a whole country fits once it is staggered', () {
      final plan = staggeredPlan(
        rings: [
          MapDownloadRing(label: 'Deutschland', box: germany),
          MapDownloadRing(label: 'Niedersachsen', box: lowerSaxony),
        ],
      )!;

      expect(plan.steps.map((s) => s.label), [
        'world',
        'Deutschland',
        'Niedersachsen',
      ]);

      // The world comes first and from zoom 0, so a zoomed-out map is
      // never a single tile in an empty window.
      expect(plan.steps.first.area.minZoom, 0);
      expect(plan.steps.first.area.maxZoom, MapArea.worldBaseZoom);

      // No gap between the country and the state.
      expect(
        plan.steps.last.area.minZoom,
        plan.steps[1].area.maxZoom + 1,
      );

      // The innermost ring always reaches the deepest level.
      expect(plan.steps.last.area.maxZoom, 14);

      // Whole-country coverage to zoom 12, Niedersachsen to 14 — an
      // eighth of what the flat download would have been.
      expect(plan.steps[1].area.maxZoom, 12);
      expect(plan.tileCount, lessThanOrEqualTo(MapAreaDownloader.tileLimit));
      expect(germany.tileCount ~/ plan.tileCount, greaterThanOrEqualTo(3));
    });

    // With room for the whole state at full detail, holding a level back
    // for the town would be less map for the same budget.
    test('a ring its neighbour already covers drops out', () {
      final plan = staggeredPlan(
        rings: [
          MapDownloadRing(label: 'Deutschland', box: germany),
          MapDownloadRing(label: 'Niedersachsen', box: lowerSaxony),
          MapDownloadRing(label: 'Hannover', box: hannover),
        ],
      )!;

      expect(plan.steps.map((s) => s.label), [
        'world',
        'Deutschland',
        'Niedersachsen',
      ]);
      expect(plan.steps.last.area.maxZoom, 14);

      // Bands are contiguous and never overlap, which is what makes the
      // tile count a plain sum.
      for (var i = 1; i < plan.steps.length; i++) {
        expect(
          plan.steps[i].area.minZoom,
          plan.steps[i - 1].area.maxZoom + 1,
        );
      }
      expect(plan.tileCount, lessThanOrEqualTo(MapAreaDownloader.tileLimit));
    });

    test('a tight budget still produces a usable plan', () {
      final plan = staggeredPlan(
        rings: [
          MapDownloadRing(label: 'Deutschland', box: germany),
          MapDownloadRing(label: 'Niedersachsen', box: lowerSaxony),
          MapDownloadRing(label: 'Hannover', box: hannover),
        ],
        budget: 20000,
      )!;

      expect(plan.tileCount, lessThanOrEqualTo(20000));
      expect(plan.steps.last.area.maxZoom, 14);
      // The country is still whole, just coarser, and all three rings
      // now earn their place — behind the world base.
      expect(plan.steps, hasLength(4));
      expect(plan.steps.first.area.minZoom, 0);
      for (var i = 1; i < plan.steps.length; i++) {
        expect(plan.steps[i].area.minZoom, plan.steps[i - 1].area.maxZoom + 1);
      }
    });

    test('the world is always in there, and it is cheap', () {
      final plan = staggeredPlan(
        rings: [MapDownloadRing(label: 'Hannover', box: hannover)],
        worldLabel: 'Welt',
      )!;

      final base = plan.steps.first;
      expect(base.label, 'Welt');
      expect(base.area.minZoom, 0);
      expect(base.area.maxZoom, MapArea.worldBaseZoom);
      // The whole planet, not the box of any ring: at zoom 3 one tile
      // spans Barcelona to Warsaw, and a download that only took the
      // tiles its own box touched left that one square floating in grey.
      expect(base.area.minLongitude, -180);
      expect(base.area.maxLongitude, 180);
      // 341 tiles against a budget of a hundred thousand.
      expect(base.tileCount, 341);
    });

    // What "download all of Europe" actually gets you, and at what cost
    // to the rings inside it.
    test('a continent fits as the outermost ring', () {
      final plan = staggeredPlan(
        rings: [
          MapDownloadRing(label: 'Europa', box: Continent.europe.areaAt(14)),
          MapDownloadRing(label: 'Deutschland', box: germany),
          MapDownloadRing(label: 'Niedersachsen', box: lowerSaxony),
        ],
        worldLabel: 'Welt',
      )!;

      expect(plan.steps.map((s) => s.label), [
        'Welt',
        'Europa',
        'Deutschland',
        'Niedersachsen',
      ]);

      // Europe down to zoom 9 — regional roads — and the innermost ring
      // still reaches street level. That is the trade: the country gives
      // up its middle levels to the continent.
      expect(plan.steps[1].area.maxZoom, 9);
      expect(plan.steps.last.area.maxZoom, 14);
      expect(plan.tileCount, lessThanOrEqualTo(MapAreaDownloader.tileLimit));

      // Contiguous, so the tile count stays a plain sum.
      for (var i = 1; i < plan.steps.length; i++) {
        expect(plan.steps[i].area.minZoom, plan.steps[i - 1].area.maxZoom + 1);
      }
    });

    test('nothing fits is an answer, not a crash', () {
      final world = box(-180, -85, 180, 85);
      expect(
        staggeredPlan(
          rings: [
            MapDownloadRing(label: 'Welt', box: world),
            MapDownloadRing(label: 'Welt', box: world),
          ],
          budget: 100,
        ),
        isNull,
      );
    });

    test('every tile is offered once', () {
      final plan = staggeredPlan(
        rings: [
          MapDownloadRing(label: 'Niedersachsen', box: lowerSaxony),
          MapDownloadRing(label: 'Hannover', box: hannover),
        ],
        budget: 3000,
      )!;

      final tiles = plan.tiles().toList();
      expect(tiles, hasLength(plan.tileCount));
      expect(
        tiles.map((t) => '${t.z}/${t.x}/${t.y}').toSet(),
        hasLength(tiles.length),
      );
    });
  });
}
