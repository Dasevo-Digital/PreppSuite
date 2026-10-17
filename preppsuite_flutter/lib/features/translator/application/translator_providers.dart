import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  final Map<TranslatorDirection, TranslatorInstallProgress> progress;
  final Map<TranslatorDirection, Object> failed;
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
      );
    } on Object catch (error) {
      state = TranslatorInstallState(
        progress: {...state.progress}..remove(direction),
        failed: {...state.failed, direction: error},
      );
    }
    ref.invalidate(installedTranslatorPacksProvider);
  }

  Future<void> remove(TranslatorDirection direction) async {
    await ref.read(translatorStoreProvider).remove(direction);
    ref.invalidate(installedTranslatorPacksProvider);
  }

  void _set(TranslatorDirection direction, TranslatorInstallProgress value) {
    state = TranslatorInstallState(
      progress: {...state.progress, direction: value},
      failed: {...state.failed}..remove(direction),
    );
  }
}

final translatorInstallProvider =
    NotifierProvider<TranslatorInstallController, TranslatorInstallState>(
      TranslatorInstallController.new,
    );
