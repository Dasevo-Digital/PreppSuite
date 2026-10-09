import 'dart:async' show unawaited;

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/closes_databases_on_exit.dart';
import 'core/former_identity.dart';
import 'core/local_database_encryption.dart';
import 'core/photo_vault.dart';
import 'core/portable_data.dart';
import 'features/downloads/application/relink_files.dart';
import 'features/inventory/application/inventory_photo_service.dart';
import 'features/inventory/application/open_food_facts_service.dart';
import 'core/error_log.dart';
import 'core/error_display.dart';
import 'core/app_database_directory.dart';

import 'package:flutter/foundation.dart';

/// PreppSuite runs entirely on the device.
///
/// There is no client to build and no address to point it at any more: the
/// warning feeds are public and fetched directly, and everything else lives
/// in the local database. What used to happen here — building the Serverpod
/// client, restoring an auth session, resolving a server URL — is simply
/// gone.
void main(List<String> args) async {
  // The Linux and Windows article window is a second copy of this
  // executable, launched to draw the title bar above the web view. It
  // recognises itself by the arguments it was given and never gets as far
  // as the app; on every other platform there are none and this is false.
  if (runWebViewTitleBarWidget(args)) return;

  WidgetsFlutterBinding.ensureInitialized();

  // Every error that reaches the top, from a build or from a future
  // nobody awaited, goes into the log on this device (#141). Flutter's own
  // handling stays as it was beside it.
  final presentError = FlutterError.onError;
  FlutterError.onError = (details) {
    ErrorLog.instance.record(
      details.exception,
      details.stack,
      context: details.library,
    );
    presentError?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorLog.instance.record(error, stack, context: 'async');
    return true;
  };
  // A sentence instead of a grey patch where a part of a screen fails.
  // Debug builds keep Flutter's red one, which says more to whoever is
  // fixing it.
  if (kReleaseMode) ErrorWidget.builder = friendlyErrorWidget;

  // First of all: the folder the household was in under the former
  // identifier (de.status403.preppsuite) holds the pointer to a chosen
  // folder as well as the databases. It cannot throw and it cannot stop
  // startup.
  await takeOverFormerIdentity();

  // Before anything reads a setting or opens a database: this is what
  // decides whether they come from the platform's own place or from a
  // folder on the disk the program is being carried on. It cannot throw
  // and it cannot stop startup — the worst it does is decide that this
  // is an ordinary installation.
  await startPortableData();

  // The log lives with the app's own files, on the stick if it is
  // carried on one.
  try {
    ErrorLog.instance.attach(await appSupportDirectory());
  } on Object {
    // Kept in memory until the next start.
  }

  // Establish the data-key state before any provider can open Drift. New
  // households start encrypted; existing ones remain recoverably readable
  // until Settings has created a backup and starts the explicit upgrade.
  //
  // It never throws out of here. A device that cannot hand over the key
  // right now leaves the app in recovery, where `LocalDataGate` explains
  // it -- a crash before `runApp` would leave nothing at all.
  await LocalDatabaseEncryption.instance.initializeOrMarkUnavailable();

  // After the key, because the document list is encrypted; before the
  // providers, because they read what this may rewrite. An update can
  // cut the app off from the map and the archives while the files sit
  // exactly where they were -- see `relink_files.dart`. Bounded, and it
  // cannot stop startup.
  await relinkMovedFiles();

  // Seals the pictures an older version left in the clear, in the
  // background. A picture that is opened first is sealed by that read;
  // this is for the ones nobody looks at. See `photo_vault.dart`.
  unawaited(_sealStoredPhotos());

  OpenFoodFactsService.configure();

  runApp(
    const ProviderScope(
      child: ClosesDatabasesOnExit(child: PreppSuiteApp()),
    ),
  );
}

Future<void> _sealStoredPhotos() async {
  try {
    await const PhotoVault().sealDirectory(
      await const InventoryPhotoService().photosDirectory(),
    );
  } on Object {
    // No support directory yet, or no key: nothing to seal, and the
    // next start tries again.
  }
}
