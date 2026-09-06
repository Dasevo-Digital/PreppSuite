import 'package:flutter/foundation.dart';

/// Whether this platform can be asked where it is.
///
/// `geolocator` covers Android, iOS, macOS, Windows and the web. On Linux
/// there is no implementation at all, so the call does not fail politely
/// — it throws a missing-plugin error from under a button that looks like
/// it should work. Better to not offer it.
bool get supportsDeviceLocation =>
    !kIsWeb && supportsDeviceLocationOn(defaultTargetPlatform);

bool supportsDeviceLocationOn(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android ||
  TargetPlatform.iOS ||
  TargetPlatform.macOS ||
  TargetPlatform.windows => true,
  TargetPlatform.linux || TargetPlatform.fuchsia => false,
};
