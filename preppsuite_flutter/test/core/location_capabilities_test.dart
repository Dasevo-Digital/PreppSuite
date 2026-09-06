import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/location_capabilities.dart';

void main() {
  test('Linux is the platform without a location implementation', () {
    // geolocator ships Android, iOS, macOS and Windows. On Linux the call
    // throws a missing-plugin error, which under a button reads as the
    // button doing nothing.
    expect(supportsDeviceLocationOn(TargetPlatform.linux), isFalse);
    expect(supportsDeviceLocationOn(TargetPlatform.fuchsia), isFalse);

    for (final platform in [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    ]) {
      expect(supportsDeviceLocationOn(platform), isTrue, reason: '$platform');
    }
  });
}
