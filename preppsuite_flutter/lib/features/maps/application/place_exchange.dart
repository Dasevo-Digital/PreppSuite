/// Own places, in the two formats every other map program reads.
///
/// The places were a one-way street: typed in here and leaving only when
/// the phone did. A meeting point, a shut-off valve, the way out of the
/// valley — a household that worked those out on a paper map, or in
/// Organic Maps, or on a walk with a handheld receiver, had to type them
/// again; and a plan that cannot leave the app it was made in is a plan
/// that ends with the app.
///
/// So both directions, in both of the formats that are actually
/// exchanged. GPX is what receivers and hiking software speak; KML is what
/// the mapping services and Google Earth speak. Reading sniffs which one
/// it has rather than trusting the file extension, because a file that
/// came through a chat app rarely still has one.
///
/// **The trap this file exists to get right**: GPX writes latitude and
/// longitude as named attributes, and KML writes them as one comma-list in
/// the other order — longitude first. Swapping them puts a German
/// household in Somalia, and it looks perfectly plausible on the way
/// through.
library;

import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import 'personal_place.dart';

/// The places as a GPX 1.1 document.
String placesToGpx(List<PersonalPlace> places) {
  final builder = XmlBuilder()..processing('xml', 'version="1.0"');
  builder.element(
    'gpx',
    attributes: {
      'version': '1.1',
      'creator': 'PreppSuite',
      'xmlns': 'http://www.topografix.com/GPX/1/1',
    },
    nest: () {
      for (final place in places) {
        builder.element(
          'wpt',
          attributes: {
            'lat': place.latitude.toString(),
            'lon': place.longitude.toString(),
          },
          nest: () {
            builder.element('name', nest: place.label);
            if (place.note case final note? when note.isNotEmpty) {
              builder.element('desc', nest: note);
            }
          },
        );
      }
    },
  );
  return builder.buildDocument().toXmlString(pretty: true);
}

/// The places as a KML document.
String placesToKml(List<PersonalPlace> places) {
  final builder = XmlBuilder()..processing('xml', 'version="1.0"');
  builder.element(
    'kml',
    attributes: {'xmlns': 'http://www.opengis.net/kml/2.2'},
    nest: () {
      builder.element(
        'Document',
        nest: () {
          for (final place in places) {
            builder.element(
              'Placemark',
              nest: () {
                builder.element('name', nest: place.label);
                if (place.note case final note? when note.isNotEmpty) {
                  builder.element('description', nest: note);
                }
                builder.element(
                  'Point',
                  nest: () {
                    // Longitude first. This is the whole reason the two
                    // formats cannot share one writer.
                    builder.element(
                      'coordinates',
                      nest: '${place.longitude},${place.latitude},0',
                    );
                  },
                );
              },
            );
          }
        },
      );
    },
  );
  return builder.buildDocument().toXmlString(pretty: true);
}

/// Every place in [raw], whether it is GPX or KML.
///
/// An empty list for anything that is neither, and for a file that is not
/// XML at all: a picked file that turns out to be a photograph is an
/// ordinary mistake, not a crash. One unusable point costs that point
/// rather than the import.
///
/// [newId] exists so a test can say what the ids will be; by default they
/// are fresh, because an id from another device means nothing here.
List<PersonalPlace> placesFromXml(String raw, {String Function()? newId}) {
  final makeId = newId ?? const Uuid().v4;
  final XmlDocument document;
  try {
    document = XmlDocument.parse(raw);
  } on XmlException {
    return const [];
  }

  final places = <PersonalPlace>[];
  for (final waypoint in document.findAllElements('wpt')) {
    final lat = double.tryParse(waypoint.getAttribute('lat') ?? '');
    final lon = double.tryParse(waypoint.getAttribute('lon') ?? '');
    if (lat == null || lon == null || !_isOnEarth(lat, lon)) continue;
    places.add(
      PersonalPlace(
        id: makeId(),
        label: _text(waypoint, 'name') ?? _fallbackLabel(lat, lon),
        latitude: lat,
        longitude: lon,
        note: _text(waypoint, 'desc'),
      ),
    );
  }

  for (final placemark in document.findAllElements('Placemark')) {
    final point = placemark.findElements('Point').firstOrNull;
    final raw = _text(point, 'coordinates');
    if (raw == null) continue;
    // "lon,lat" or "lon,lat,height", and the whitespace around it is the
    // pretty-printing of whatever wrote the file.
    final parts = raw.trim().split(',');
    if (parts.length < 2) continue;
    final lon = double.tryParse(parts[0].trim());
    final lat = double.tryParse(parts[1].trim());
    if (lat == null || lon == null || !_isOnEarth(lat, lon)) continue;
    places.add(
      PersonalPlace(
        id: makeId(),
        label: _text(placemark, 'name') ?? _fallbackLabel(lat, lon),
        latitude: lat,
        longitude: lon,
        note: _text(placemark, 'description'),
      ),
    );
  }

  return places;
}

/// [incoming] added to [existing], without the ones already there.
///
/// Importing the same file twice is something people do — they are not
/// sure it worked the first time — and it must not double the list. Same
/// name in the same spot counts as the same place; the coordinates are
/// compared at five decimals, about a metre, because a point that made a
/// round trip through another program comes back with a different last
/// digit.
List<PersonalPlace> mergePlaces(
  List<PersonalPlace> existing,
  List<PersonalPlace> incoming,
) {
  String key(PersonalPlace place) =>
      '${place.label.trim().toLowerCase()}@'
      '${place.latitude.toStringAsFixed(5)},'
      '${place.longitude.toStringAsFixed(5)}';

  final have = {for (final place in existing) key(place)};
  return [
    ...existing,
    for (final place in incoming)
      if (have.add(key(place))) place,
  ];
}

bool _isOnEarth(double lat, double lon) =>
    lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;

String _fallbackLabel(double lat, double lon) =>
    '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';

String? _text(XmlElement? parent, String name) {
  final value = parent?.findElements(name).firstOrNull?.innerText.trim();
  return value == null || value.isEmpty ? null : value;
}
