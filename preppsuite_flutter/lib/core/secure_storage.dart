import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The device's key store, and the one way this app reaches it.
///
/// `resetOnError` is off, which is why there is one place for this (#335).
/// Left at the plugin's default, any exception while reading from the
/// Android keystore deletes the entry, or everything, and answers as if
/// nothing had been there. For most apps that is a login to repeat. Here
/// the entry is the key to the household's database, and a keystore that
/// fails once would have cost the data for good. With the option off a
/// failed read stays a failed read: the app comes up in recovery and can
/// ask again.
const appSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(resetOnError: false),
);
