import 'dart:io';

import 'package:serverpod/serverpod.dart';

/// Conventional location for the service-account key: drop the file
/// Firebase hands you in place and there is nothing to configure. The
/// Serverpod template already git-ignores this exact path.
const firebaseServiceAccountFile = 'config/firebase_service_account_key.json';

/// Password key holding the whole key as one JSON string, for deployments
/// that inject secrets rather than mount files. Serverpod maps the
/// environment variable `SERVERPOD_PASSWORD_firebaseServiceAccount` onto
/// this key on its own — no registration needed.
const firebaseServiceAccountPassword = 'firebaseServiceAccount';

/// Finds the Firebase service-account key, or null if there is none.
String? loadFirebaseServiceAccount(Session session) {
  return resolveFirebaseServiceAccount(
    password: session.passwords[firebaseServiceAccountPassword],
    path: firebaseServiceAccountFile,
  );
}

/// The lookup itself, with both sources given explicitly so it can be
/// tested without a server.
///
/// The password wins over the file. Explicit configuration should not be
/// quietly overruled by a stray file left in a container image — and the
/// password is also how the `SERVERPOD_PASSWORD_firebaseServiceAccount`
/// environment variable arrives.
String? resolveFirebaseServiceAccount({
  required String? password,
  required String path,
}) {
  if (password != null && password.trim().isNotEmpty) return password;

  final file = File(path);
  if (!file.existsSync()) return null;

  try {
    final contents = file.readAsStringSync();
    return contents.trim().isEmpty ? null : contents;
  } on FileSystemException {
    // Unreadable is the same as absent as far as the caller is concerned:
    // push stays off and the server keeps running.
    return null;
  }
}
