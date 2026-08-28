import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../../../core/server_url.dart';
import '../../../core/server_url_dialog.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../main.dart';
import '../../household/presentation/household_gate.dart';

/// Shows the sign-in UI until the user is authenticated, then shows
/// [HouseholdGate]. Reacts live to [client.auth.authInfoListenable] so
/// signing out anywhere in the app drops straight back to sign-in.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Rebuilds the whole signed-out branch when the address changes, so
    // the sign-in widget below is handed the newly built client.
    final currentServer = ref.watch(serverUrlProvider);

    return ValueListenableBuilder(
      valueListenable: client.auth.authInfoListenable,
      builder: (context, authInfo, _) {
        if (authInfo == null) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      key: ValueKey(currentServer),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SignInWidget(client: client),
                        const SizedBox(height: 24),
                        // The only way out of a wrong address: Settings
                        // sits behind this screen, so without this button
                        // a misconfigured install could never be fixed.
                        Text(
                          currentServer,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () => ServerUrlDialog.show(context),
                          child: Text(l10n.serverAddressChangeAction),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return const HouseholdGate();
      },
    );
  }
}
