import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_client/preppsuite_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'app.dart';
import 'features/inventory/application/open_food_facts_service.dart';

/// Global Serverpod client used to talk to the self-hosted backend.
///
/// Kept as a simple top-level global (Serverpod's own scaffolding
/// convention) rather than behind a DI layer, since there is exactly one
/// client for the whole app.
late final Client client;

/// The resolved server address, shown read-only in Settings so a
/// self-hoster can confirm which backend they're actually talking to —
/// there's no fixed SaaS endpoint to assume.
late final String serverUrl;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On a physical device, point this at your self-hosted server's address,
  // e.g. `flutter run --dart-define=SERVER_URL=https://preppsuite.example.com/`.
  // Otherwise it is read from assets/config.json or defaults to localhost.
  serverUrl = await getServerUrl();

  client = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager();

  client.auth.initialize();

  OpenFoodFactsService.configure();

  runApp(const ProviderScope(child: PreppSuiteApp()));
}
