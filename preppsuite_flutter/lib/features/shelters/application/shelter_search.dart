import 'geo_bounds.dart';
import 'shelter_classification.dart';

typedef ShelterSource = Future<List<ClassifiedShelter>> Function(
  GeoBoundingBox bounds,
);

class ShelterSearchResult {
  const ShelterSearchResult(
    this.shelters,
    this.pending,
    this.successfulSources,
    this.wwbotaError,
    this.overpassError,
  );
  final List<ClassifiedShelter> shelters;
  final int pending;
  final int successfulSources;

  /// Why a source came back empty, or null when it did not.
  ///
  /// The reason used to be caught and dropped, which left the screen
  /// saying "OpenStreetMap/Overpass konnte nicht geladen werden" and
  /// nothing else — the same sentence for a rate limit that clears in
  /// seconds, a query that timed out and no network at all.
  final Object? wwbotaError;
  final Object? overpassError;

  bool get wwbotaFailed => wwbotaError != null;
  bool get overpassFailed => overpassError != null;

  /// An empty list can still be a current, successful answer. This matters
  /// for the cache: replacing a known list with a confirmed empty result is
  /// correct; replacing it because both public services timed out is not.
  bool get hasSuccessfulSource => successfulSources > 0;
}

/// Independent sources publish partial results; only the newest search may win.
class ShelterSearch {
  ShelterSearch({
    required this.wwbota,
    required this.overpass,
    this.timeout = const Duration(seconds: 30),
  });
  final ShelterSource wwbota;
  final ShelterSource overpass;
  final Duration timeout;
  int _generation = 0;
  void cancel() => _generation++;

  Future<void> search(
    GeoBoundingBox bounds,
    void Function(ShelterSearchResult) publish,
  ) async {
    final generation = ++_generation;
    final results = <List<ClassifiedShelter>>[[], []];
    final failed = <Object?>[null, null];
    var pending = 2;
    var successfulSources = 0;
    void emit() {
      if (generation == _generation) {
        publish(
          ShelterSearchResult(
            [...results[0], ...results[1]],
            pending,
            successfulSources,
            failed[0],
            failed[1],
          ),
        );
      }
    }

    emit();
    Future<void> load(int index, ShelterSource source) async {
      try {
        results[index] = await source(bounds).timeout(timeout);
        successfulSources++;
      } catch (error) {
        failed[index] = error;
      }
      pending--;
      emit();
    }

    await Future.wait([load(0, wwbota), load(1, overpass)]);
  }
}
