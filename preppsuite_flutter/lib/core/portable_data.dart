import 'dart:io';

import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'portable_location.dart';
import 'portable_preferences.dart';

export 'portable_location.dart';

/// Where this copy keeps its data, decided once at startup.
///
/// A global because it has to be answered before anything else runs —
/// the settings store is swapped out on the strength of it, and the
/// database directory is resolved from it — and because there is exactly
/// one answer per process.
PortableLocation get portableLocation => _location;

PortableLocation _location = const PortableLocation(
  directory: null,
  source: PortableSource.installed,
);

/// Works out where the data lives and points the settings at it.
///
/// Called from `main` before anything reads a setting or opens a
/// database. It never throws: every way this can go wrong ends in an
/// ordinary installation, because an app that will not start is worse
/// than an app that started in the wrong folder and says so.
Future<PortableLocation> startPortableData({
  Map<String, String>? environment,
  String? executablePath,
}) async {
  PortableLocation resolved;
  try {
    resolved = await resolvePortableLocation(
      environment: environment,
      executablePath: executablePath,
    );
  } on Object {
    resolved = const PortableLocation(
      directory: null,
      source: PortableSource.installed,
    );
  }

  final directory = resolved.directory;
  if (directory == null) {
    _location = resolved;
    return resolved;
  }

  try {
    // Taken hold of before ours is registered: on Linux and Windows the
    // platform's store is an ordinary Dart object rather than a channel,
    // so once it has been replaced there is no asking it anything.
    final installed = SharedPreferencesStorePlatform.instance;
    final store = await PortablePreferencesStore.open(directory);
    SharedPreferencesStorePlatform.instance = store;
    await adoptInstalledPreferences(store, installed);
  } on Object {
    // The folder went away between being checked and being written to —
    // a stick pulled during startup is the obvious case. Carry on as an
    // ordinary installation rather than with settings nobody can save.
    _location = const PortableLocation(
      directory: null,
      source: PortableSource.installed,
    );
    return _location;
  }

  _location = resolved;
  return resolved;
}

/// Forgets the resolved location. Tests only.
void resetPortableData() {
  _location = const PortableLocation(
    directory: null,
    source: PortableSource.installed,
  );
}

/// The folder photos, databases and the web view's working files go in.
///
/// One place, so that turning portability on moves all of them together
/// rather than most of them.
Directory? get portableSupportDirectory => _location.directory;
