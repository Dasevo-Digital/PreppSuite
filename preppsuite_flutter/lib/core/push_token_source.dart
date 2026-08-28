import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:preppsuite_client/preppsuite_client.dart' show PushPlatform;

/// Where the device's push registration token comes from.
///
/// An interface rather than a direct `firebase_messaging` call because the
/// Firebase SDK cannot be added until the project's configuration files
/// exist — `google-services.json` on Android, `GoogleService-Info.plist` on
/// iOS — and adding it without them makes the app fail to build rather than
/// fail gracefully. Everything above this line is finished and testable
/// now; wiring Firebase in later means writing one more implementation of
/// this and choosing it in [pushTokenSourceProvider], and touching nothing
/// else.
abstract interface class PushTokenSource {
  /// Whether push is usable at all on this build and platform.
  bool get isAvailable;

  /// The current registration token, or null if none could be obtained
  /// (permission refused, no network on first run, no Firebase project).
  Future<String?> token();

  /// Fires whenever the service issues a new token. Tokens rotate on
  /// reinstall, on restore-to-a-new-device, and occasionally on their own —
  /// a registration that is never refreshed goes quietly dead.
  Stream<String> get onTokenRefresh;
}

/// The implementation in use until Firebase is configured.
///
/// Reports itself unavailable, which leaves the app exactly where it was:
/// local notifications for warnings that arrive while it is running, and
/// nothing while it is closed.
class UnavailablePushTokenSource implements PushTokenSource {
  const UnavailablePushTokenSource();

  @override
  bool get isAvailable => false;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
}

/// Which push service this device is reachable through, or null on the
/// platforms that have none.
///
/// Desktop and web are deliberately excluded: macOS could technically be
/// pushed through APNs, but a laptop is not what someone checks for a
/// civil-protection warning at three in the morning, and supporting it
/// would mean a second Apple credential for no practical gain.
PushPlatform? currentPushPlatform() {
  if (kIsWeb) return null;
  if (Platform.isAndroid) return PushPlatform.android;
  if (Platform.isIOS) return PushPlatform.ios;
  return null;
}
