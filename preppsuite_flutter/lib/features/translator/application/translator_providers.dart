import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../phrasebook/application/phrasebook.dart' show PhraseLanguage;
import 'translator_catalogue.dart';
import 'translator_engine.dart';
import 'translator_store.dart';

/// Whether this build carries the translator library. A provider so a
/// widget test can say either.
final translatorAvailableProvider = Provider<bool>(
  (ref) => translatorAvailable,
);

/// The translation itself, behind a provider for the same reason.
final translateTextProvider =
    Provider<Future<String> Function(String, List<InstalledTranslatorPack>)>(
      (ref) => translateText,
    );

final translatorStoreProvider = Provider<TranslatorStore>(
  (ref) => TranslatorStore(),
);

/// The directions on this device.
final installedTranslatorPacksProvider =
    FutureProvider<List<InstalledTranslatorPack>>(
      (ref) => ref.watch(translatorStoreProvider).installed(),
    );

/// Mozilla's list, asked for only when a direction is missing -- the
/// screen opens without the network whenever the packs are already here.
final translatorCatalogueProvider =
    FutureProvider.autoDispose<TranslatorCatalogue>(
      (ref) => TranslatorCatalogue.fetch(),
    );

/// Directions being fetched, with how far each has got, and the last
/// failure per direction.
class TranslatorInstallState {
  const TranslatorInstallState({
    this.progress = const {},
    this.failed = const {},
    this.batch,
  });

  final Map<TranslatorDirection, TranslatorInstallProgress> progress;
  final Map<TranslatorDirection, Object> failed;

  /// "Alle Sprachpakete laden" while it runs (#182), else null.
  final TranslatorBatch? batch;
}

/// Every missing direction fetched in one go, one after another.
class TranslatorBatch {
  const TranslatorBatch({
    required this.total,
    this.done = 0,
    this.stopping = false,
  });

  /// Packs this run set out to fetch, and how many of them are behind it,
  /// failed ones included.
  final int total;
  final int done;

  /// Asked to stop: the pack on its way is finished, no further one is
  /// started.
  final bool stopping;

  TranslatorBatch copyWith({int? done, bool? stopping}) => TranslatorBatch(
    total: total,
    done: done ?? this.done,
    stopping: stopping ?? this.stopping,
  );
}

/// The directions of [catalogue] that are not among [present], in the
/// order a batch fetches them: those with German first, so that German
/// to and from every language works before the rest arrives.
List<TranslatorPack> missingTranslatorPacks(
  TranslatorCatalogue catalogue,
  Iterable<TranslatorDirection> present,
) {
  final have = present.toSet();
  int rank(TranslatorDirection d) =>
      d.from == PhraseLanguage.de || d.to == PhraseLanguage.de ? 0 : 1;
  return [
    for (final pack in catalogue.packs.values)
      if (!have.contains(pack.direction)) pack,
  ]..sort((a, b) {
    final byRank = rank(a.direction).compareTo(rank(b.direction));
    if (byRank != 0) return byRank;
    final byFrom = a.direction.from.index.compareTo(b.direction.from.index);
    return byFrom != 0
        ? byFrom
        : a.direction.to.index.compareTo(b.direction.to.index);
  });
}

class TranslatorInstallController extends Notifier<TranslatorInstallState> {
  @override
  TranslatorInstallState build() => const TranslatorInstallState();

  Future<void> install(TranslatorPack pack) async {
    final direction = pack.direction;
    if (state.progress.containsKey(direction)) return;
    _set(direction, const TranslatorInstallProgress(received: 0, total: 1));
    try {
      await for (final progress
          in ref.read(translatorStoreProvider).install(pack)) {
        _set(direction, progress);
      }
      state = TranslatorInstallState(
        progress: {...state.progress}..remove(direction),
        failed: {...state.failed}..remove(direction),
        batch: state.batch,
      );
    } on Object catch (error) {
      state = TranslatorInstallState(
        progress: {...state.progress}..remove(direction),
        failed: {...state.failed, direction: error},
        batch: state.batch,
      );
    }
    ref.invalidate(installedTranslatorPacksProvider);
  }

  /// Fetches every pack in [packs], one after another (#182).
  ///
  /// One at a time and not all at once: a pack is some 20 to 50 MB, all
  /// of them several hundred, and a phone on a weak connection that
  /// starts eighteen downloads finishes none. A pack that fails is left
  /// for the next run and does not stop the others; its error stands in
  /// [TranslatorInstallState.failed] as for a single download.
  Future<void> installAll(List<TranslatorPack> packs) async {
    if (state.batch != null || packs.isEmpty) return;
    _setBatch(TranslatorBatch(total: packs.length));
    for (final pack in packs) {
      if (state.batch?.stopping ?? true) break;
      await install(pack);
      final batch = state.batch;
      if (batch != null) _setBatch(batch.copyWith(done: batch.done + 1));
    }
    _setBatch(null);
  }

  /// Stops [installAll] after the pack it is fetching.
  void stopAll() {
    final batch = state.batch;
    if (batch != null) _setBatch(batch.copyWith(stopping: true));
  }

  void _setBatch(TranslatorBatch? batch) {
    state = TranslatorInstallState(
      progress: state.progress,
      failed: state.failed,
      batch: batch,
    );
  }

  Future<void> remove(TranslatorDirection direction) async {
    await ref.read(translatorStoreProvider).remove(direction);
    ref.invalidate(installedTranslatorPacksProvider);
  }

  void _set(TranslatorDirection direction, TranslatorInstallProgress value) {
    state = TranslatorInstallState(
      progress: {...state.progress, direction: value},
      failed: {...state.failed}..remove(direction),
      batch: state.batch,
    );
  }
}

final translatorInstallProvider =
    NotifierProvider<TranslatorInstallController, TranslatorInstallState>(
      TranslatorInstallController.new,
    );
