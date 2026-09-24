import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/local_database_encryption.dart';
import 'core/portable_data.dart';
import 'features/inventory/application/open_food_facts_service.dart';

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

  // Before anything reads a setting or opens a database: this is what
  // decides whether they come from the platform's own place or from a
  // folder on the disk the program is being carried on. It cannot throw
  // and it cannot stop startup — the worst it does is decide that this
  // is an ordinary installation.
  await startPortableData();

  // Establish the data-key state before any provider can open Drift. New
  // households start encrypted; existing ones remain recoverably readable
  // until Settings has created a backup and starts the explicit upgrade.
  //
  // It never throws out of here. A device that cannot hand over the key
  // right now leaves the app in recovery, where `LocalDataGate` explains
  // it -- a crash before `runApp` would leave nothing at all.
  await LocalDatabaseEncryption.instance.initializeOrMarkUnavailable();

  OpenFoodFactsService.configure();

  runApp(const ProviderScope(child: PreppSuiteApp()));
}
