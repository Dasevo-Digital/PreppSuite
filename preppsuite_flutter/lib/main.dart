import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_client/preppsuite_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/prefs_auth_storage.dart';
import 'core/server_url.dart';
import 'features/inventory/application/open_food_facts_service.dart';

/// Global Serverpod client used to talk to the self-hosted backend.
///
/// Kept as a simple top-level global (Serverpod's own scaffolding
/// convention) rather than behind a DI layer, since there is exactly one
/// client for the whole app.
///
/// Not `final`: the address is a setting now, so switching servers rebuilds
/// this rather than requiring a new build of the app. See
/// [connectToServer].
late Client client;

/// The address [client] is currently pointed at, shown in Settings so a
/// self-hoster can confirm which backend they're actually talking to —
/// there's no fixed SaaS endpoint to assume.
late String serverUrl;

/// Points [client] at [url].
///
/// Called once at startup and again whenever the address changes. The
/// client holds the auth session, so a new one starts signed out — which
/// is correct: an account on one server says nothing about another.
void connectToServer(String url) {
  serverUrl = url;
  client = Client(url)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager(
      // See PrefsAuthKeyValueStorage's doc comment: avoids needing a
      // Keychain-Sharing entitlement, which needs real code signing.
      storage: KeyValueClientAuthSuccessStorage(
        keyValueStorage: PrefsAuthKeyValueStorage(),
      ),
    );
  client.auth.initialize();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // What the app was built with: `--dart-define=SERVER_URL=...`, otherwise
  // assets/config.json, otherwise localhost.
  ServerUrlController.compiledDefault = await getServerUrl();

  // A stored address wins over the compiled one. Read here rather than via
  // the provider because the client has to exist before the first frame,
  // and the provider's own load is asynchronous.
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString(serverUrlPrefsKey);

  connectToServer(
    stored != null && stored.isNotEmpty
        ? stored
        : ServerUrlController.compiledDefault,
  );

  OpenFoodFactsService.configure();

  runApp(const ProviderScope(child: PreppSuiteApp()));
}
