import 'dart:typed_data';

import 'package:vector_tile/raw/raw_vector_tile.dart' as raw;

/// One point to put in a made-up tile, in the tile's own coordinates.
typedef TestPoi = ({String subclass, String? name, int x, int y});

/// Encodes a `poi` layer the way the OpenMapTiles schema writes one.
Uint8List poiTile(List<TestPoi> points, {int extent = 4096}) {
  final keys = <String>['class', 'subclass', 'name'];
  final values = <String>[];
  int valueIndex(String value) {
    final at = values.indexOf(value);
    if (at >= 0) return at;
    values.add(value);
    return values.length - 1;
  }

  final features = <raw.VectorTile_Feature>[];
  for (final point in points) {
    final tags = <int>[
      1, valueIndex(point.subclass), //
      if (point.name case final name?) ...[2, valueIndex(name)],
    ];
    features.add(
      raw.VectorTile_Feature(
        type: raw.VectorTile_GeomType.POINT,
        tags: tags,
        // MoveTo once, then the two coordinates zig-zag encoded.
        geometry: [9, _zigZag(point.x), _zigZag(point.y)],
      ),
    );
  }

  final tile = raw.VectorTile(
    layers: [
      raw.VectorTile_Layer(
        version: 2,
        name: 'poi',
        extent: extent,
        keys: keys,
        values: [
          for (final value in values) raw.VectorTile_Value(stringValue: value),
        ],
        features: features,
      ),
    ],
  );
  return tile.writeToBuffer();
}

int _zigZag(int value) => (value << 1) ^ (value >> 31);
