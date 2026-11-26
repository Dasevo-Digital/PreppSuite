import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'local_database_encryption.dart';
import 'portable_location.dart';
import 'portable_preferences.dart';
import 'portable_takeover.dart';

export 'portable_location.dart';
export 'portable_takeover.dart' show PortableTakeover;

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

/// What the first start with this folder did with the installation on
/// this computer (#392). [PortableTakeover.none] unless something was
/// taken or refused; a refusal is remembered by the folder.
PortableTakeover get portableTakeover => _takeover;

PortableTakeover _takeover = PortableTakeover.none;

/// Works out where the data lives and points the settings at it.
///
/// Called from `main` before anything reads a setting or opens a
/// database. It never throws: every way this can go wrong ends in an
/// ordinary installation, because an app that will not start is worse
/// than an app that started in the wrong folder and says so.
///
/// A folder without a household takes over the one installed on this
/// computer, once (`takeOverInstallation`). [installationDirectory] and
/// [installationKeys] stand in for the platform's in tests.
Future<PortableLocation> startPortableData({
  Map<String, String>? environment,
  String? executablePath,
  Future<Directory> Function()? installationDirectory,
  LocalDatabaseKeyStorage? installationKeys,
}) async {
  _takeover = PortableTakeover.none;
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

  // Taken hold of before ours is registered: on Linux and Windows the
  // platform's store is an ordinary Dart object rather than a channel,
  // so once it has been replaced there is no asking it anything.
  final installed = SharedPreferencesStorePlatform.instance;
  try {
    final store = await PortablePreferencesStore.open(directory);
    SharedPreferencesStorePlatform.instance = store;
    _takeover = await takeOverInstallation(
      folder: directory,
      installation: await _installation(installationDirectory),
      preferences: store,
      installedPreferences: installed,
      installationKey: () => LocalDatabaseEncryption.readInstallationKey(
        installationKeys ?? const SecureLocalDatabaseKeyStorage(),
      ),
    );
    if (_takeover == PortableTakeover.none) {
      // A refusal at an earlier start, for the settings card to say.
      _takeover =
          PortableTakeover.fromName(
            (await store.getAll())['flutter.${PortableTakeover.preferenceKey}'],
          ) ??
          PortableTakeover.none;
    }
  } on Object {
    // The folder went away between being checked and being written to —
    // a stick pulled during startup is the obvious case — or a takeover
    // could not be moved into place, which the next start finishes. Carry
    // on as an ordinary installation rather than with settings nobody can
    // save, but remember which folder it was: this is the same silent
    // swap `missingChoice` exists for, just half a second later.
    SharedPreferencesStorePlatform.instance = installed;
    _takeover = PortableTakeover.none;
    _location = PortableLocation(
      directory: null,
      source: PortableSource.installed,
      missingChoice: directory.path,
    );
    return _location;
  }

  _location = resolved;
  return resolved;
}

/// Where the installation on this computer keeps its files, or null.
Future<Directory?> _installation(Future<Directory> Function()? lookUp) async {
  try {
    return await (lookUp ?? getApplicationSupportDirectory)();
  } on Object {
    // A platform without one, or a plugin that is not there: nothing to
    // take over, and nothing worth failing startup for.
    return null;
  }
}

/// Forgets the resolved location. Tests only.
void resetPortableData() {
  _location = const PortableLocation(
    directory: null,
    source: PortableSource.installed,
  );
  _takeover = PortableTakeover.none;
}

/// The folder photos, databases and the web view's working files go in.
///
/// One place, so that turning portability on moves all of them together
/// rather than most of them.
Directory? get portableSupportDirectory => _location.directory;
