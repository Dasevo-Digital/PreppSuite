import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../../../main.dart';
import '../../household/presentation/household_gate.dart';

/// Shows the sign-in UI until the user is authenticated, then shows
/// [HouseholdGate]. Reacts live to [client.auth.authInfoListenable] so
/// signing out anywhere in the app drops straight back to sign-in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
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
                    child: SignInWidget(client: client),
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
