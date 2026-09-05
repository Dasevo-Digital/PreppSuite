import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/inventory/application/open_food_facts_service.dart';

/// PreppSuite runs entirely on the device.
///
/// There is no client to build and no address to point it at any more: the
/// warning feeds are public and fetched directly, and everything else lives
/// in the local database. What used to happen here — building the Serverpod
/// client, restoring an auth session, resolving a server URL — is simply
/// gone.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  OpenFoodFactsService.configure();

  runApp(const ProviderScope(child: PreppSuiteApp()));
}
