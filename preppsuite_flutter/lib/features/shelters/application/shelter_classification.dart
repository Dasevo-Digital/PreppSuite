import 'overpass_shelter_client.dart';
import 'wwbota_client.dart';

/// Traffic-light confidence that a location is an actually-usable public
/// shelter today — deliberately conservative, since overclaiming here could
/// send someone to a sealed ruin. See the reasoning per case in
/// [classifyOverpassTags].
enum ShelterConfidence { green, yellow, red }

/// A shelter/bunker candidate from either data source, normalized to one
/// shape for the map/list UI.
class ClassifiedShelter {
  const ClassifiedShelter({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.confidence,
    required this.sourceLabel,
    this.subtitle,
  });

  /// Prefixed with the source (`wwbota:`/`osm:`) — the two sources have
  /// independent id spaces and, per the plan, are deliberately not
  /// deduplicated against each other in v1.
  final String id;
  final String name;
  final double lat;
  final double lon;
  final ShelterConfidence confidence;
  final String sourceLabel;
  final String? subtitle;
}

/// WWBOTA is an amateur-radio bunker catalogue, not an official shelter
/// registry — every entry is "a known bunker location", never an "officially
/// confirmed usable shelter", so it can never be [ShelterConfidence.green].
List<ClassifiedShelter> classifyWwbota(List<WwbotaBunker> bunkers) {
  return [
    for (final bunker in bunkers)
      ClassifiedShelter(
        id: 'wwbota:${bunker.reference}',
        name: bunker.name,
        lat: bunker.lat,
        lon: bunker.lon,
        confidence: ShelterConfidence.yellow,
        sourceLabel: 'WWBOTA/DLBOTA',
        subtitle: bunker.type,
      ),
  ];
}

List<ClassifiedShelter> classifyOverpassFeatures(
  List<OverpassShelterFeature> features,
) {
  return [
    for (final feature in features)
      ClassifiedShelter(
        id: 'osm:${feature.id}',
        name: feature.name ?? feature.tags['bunker_type'] ?? 'Bunker',
        lat: feature.lat,
        lon: feature.lon,
        confidence: classifyOverpassTags(feature.tags),
        sourceLabel: 'OpenStreetMap',
        subtitle: feature.tags['bunker_type'],
      ),
  ];
}

/// Pure classification from raw OSM tags, kept separate for direct
/// unit-testing against real captured tag combinations.
ShelterConfidence classifyOverpassTags(Map<String, String> tags) {
  final isHistoricOrDisused =
      tags['historic'] == 'yes' ||
      tags['disused'] == 'yes' ||
      tags['ruins'] == 'yes' ||
      tags['access'] == 'no';
  if (isHistoricOrDisused) return ShelterConfidence.red;

  // The only tag combination that plausibly means "a currently maintained,
  // publicly usable emergency shelter" — realistically rare in Germany
  // today (matches the reference app's own finding of effectively zero
  // confirmed public shelters), and that's reported honestly rather than
  // padded out.
  if (tags['emergency'] == 'shelter') return ShelterConfidence.green;

  return ShelterConfidence.yellow;
}
