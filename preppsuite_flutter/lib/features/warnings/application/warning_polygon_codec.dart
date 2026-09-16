import 'dart:convert';

import 'package:latlong2/latlong.dart';

import '../../../local_db/database.dart';

/// Decodes the locally cached CAP polygon representation.
///
/// A warning stays useful after the network is gone, so malformed or absent
/// geometry is deliberately treated as "no map available", never as an
/// exception that hides the rest of its text.
List<List<LatLng>> warningPolygons(Warning warning) {
  final encoded = warning.polygonsJson;
  if (encoded == null) return const [];
  try {
    final decoded = jsonDecode(encoded);
    if (decoded is! List) return const [];
    return [
      for (final polygon in decoded.whereType<String>())
        [
          for (final pair in polygon.split(RegExp(r'\s+')))
            if (pair.split(',') case [final lat, final lon])
              if (double.tryParse(lat) case final latitude?)
                if (double.tryParse(lon) case final longitude?)
                  LatLng(latitude, longitude),
        ],
    ].where((points) => points.length >= 3).toList();
  } on Object {
    return const [];
  }
}
