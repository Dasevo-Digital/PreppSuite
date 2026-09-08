import 'geo_bounds.dart';
import 'shelter_classification.dart';

typedef ShelterSource =
    Future<List<ClassifiedShelter>> Function(GeoBoundingBox bounds);

class ShelterSearchResult {
  const ShelterSearchResult(
    this.shelters,
    this.pending,
    this.wwbotaFailed,
    this.overpassFailed,
  );
  final List<ClassifiedShelter> shelters;
  final int pending;
  final bool wwbotaFailed;
  final bool overpassFailed;
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
    final failed = [false, false];
    var pending = 2;
    void emit() {
      if (generation == _generation) {
        publish(
          ShelterSearchResult(
            [...results[0], ...results[1]],
            pending,
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
      } catch (_) {
        failed[index] = true;
      }
      pending--;
      emit();
    }

    await Future.wait([load(0, wwbota), load(1, overpass)]);
  }
}
